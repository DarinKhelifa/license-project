const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
require('dotenv').config();

const run = async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  // Find all active residents without a QR token
  const residents = await User.find({
    role: 'resident',
    status: 'active',
    qrToken: null,
  });

  console.log(`Found ${residents.length} residents without QR`);

  for (const user of residents) {
    const qrToken = jwt.sign(
      {
        userId: user._id.toString(),
        name: user.name,
        apartment: user.apartment,
      },
      process.env.JWT_SECRET
      // no expiry → permanent
    );

    user.qrToken = qrToken;
    user.qrGeneratedAt = new Date();
    await user.save();

    console.log(`✅ QR generated for: ${user.name} (${user.apartment})`);
  }

  console.log('🎉 Done! All residents now have a QR code.');
  process.exit();
};

run().catch((err) => {
  console.error('❌ Error:', err);
  process.exit(1);
});