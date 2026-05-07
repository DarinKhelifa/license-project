const mongoose = require('mongoose');
const dns = require('dns');

// Force public DNS servers for MongoDB SRV lookups (fixes corporate DNS issues)
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

const DEFAULT_MAX_RETRIES = 10;

// Configure mongoose defaults
mongoose.set('strictQuery', false);

// Guard flags to avoid overlapping connection attempts
let _isConnecting = false;
let _isConnected = false;

/**
 * Connect to MongoDB with retry/backoff and improved logging.
 * This helps during transient network issues (DNS, firewall, Atlas whitelisting).
 */
const connectDB = async (retries = 0) => {
  const opts = {
    maxPoolSize: 10,
    minPoolSize: 1,
    serverSelectionTimeoutMS: 30000,
    socketTimeoutMS: 45000,
    family: 4,
    retryWrites: true,
    writeConcern: { w: 1 },
    maxIdleTimeMS: 30000,
  };

  try {
    if (_isConnected) {
      console.log('MongoDB: already connected, skipping connect call');
      return;
    }

    if (_isConnecting && retries === 0) {
      console.log('MongoDB: connection already in progress, skipping duplicate attempt');
      return;
    }

    _isConnecting = true;
    console.log(`🔌 Attempting MongoDB connection (attempt ${retries + 1})`);
    await mongoose.connect(process.env.MONGODB_URI, opts);
    _isConnecting = false;
    _isConnected = true;
    console.log('✅ MongoDB Connected');

    const states = ['disconnected', 'connected', 'connecting', 'disconnecting'];
    console.log('Mongoose readyState:', states[mongoose.connection.readyState] || mongoose.connection.readyState);

    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error (runtime):', err);
    });

    mongoose.connection.on('disconnected', () => {
      _isConnected = false;
      console.warn('MongoDB disconnected. Will attempt reconnect using backoff...');
      // Start reconnect attempts with backoff; keep retries counter
      setTimeout(() => connectDB(0), 2000);
    });
  } catch (error) {
    console.error(`❌ MongoDB connection error on attempt ${retries + 1}:`, error && error.message ? error.message : error);

    if (retries >= DEFAULT_MAX_RETRIES) {
      console.error(`Exceeded max MongoDB connection retries (${DEFAULT_MAX_RETRIES}). Exiting.`);
      // keep exit here because the application won't function without DB in production
      process.exit(1);
      return;
    }

    // Exponential backoff (capped)
    const delay = Math.min(30000, 1000 * Math.pow(2, retries));
    console.log(`Retrying MongoDB connection in ${delay / 1000}s... (next attempt ${retries + 2})`);
    setTimeout(() => connectDB(retries + 1), delay);
  }
};

module.exports = connectDB;