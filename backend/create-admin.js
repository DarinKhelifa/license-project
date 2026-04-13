const mongoose = require('mongoose');
const User = require('./src/models/User');
require('dotenv').config();

const createAdmin = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/orelax');

    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: 'admin@orelax.com' });
    if (existingAdmin) {
      console.log('Admin user already exists');
      process.exit(0);
    }

    // Create admin user
    const admin = await User.create({
      name: 'Admin User',
      email: 'admin@orelax.com',
      password: 'admin123',
      phone: '1234567890',
      apartment: 'Admin',
      role: 'admin',
      status: 'active'
    });

    console.log('Admin user created successfully!');
    console.log('Email: admin@orelax.com');
    console.log('Password: admin123');

    process.exit(0);
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
};

createAdmin();