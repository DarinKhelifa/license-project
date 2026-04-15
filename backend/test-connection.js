// Test MongoDB connection with DNS debugging
const mongoose = require('mongoose');
const dns = require('dns');
const { promisify } = require('util');

// Force public DNS for MongoDB
dns.setServers(['8.8.8.8', '8.8.4.4']);

require('dotenv').config();

async function testConnection() {
  try {
    console.log('🔍 Testing MongoDB connection with public DNS...');
    console.log('📍 Current DNS servers:', dns.getServers());
    
    await mongoose.connect(process.env.MONGODB_URI, {
      maxPoolSize: 10,
      minPoolSize: 5,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      family: 4,
      retryWrites: true,
    });
    
    console.log('✅ MongoDB connected successfully!');
    console.log('📊 Connection info:', {
      host: mongoose.connection.host,
      db: mongoose.connection.name,
      state: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected'
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    process.exit(1);
  }
}

testConnection();
