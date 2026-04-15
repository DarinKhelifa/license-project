const mongoose = require('mongoose');
const dns = require('dns');

// Force public DNS servers for MongoDB SRV lookups (fixes corporate DNS issues)
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      maxPoolSize: 10,
      minPoolSize: 5,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      family: 4,
      retryWrites: true,
      writeConcern: { w: 1 },
      maxIdleTimeMS: 30000,
    });
    console.log('✅ MongoDB Connected...');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

module.exports = connectDB;