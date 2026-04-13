const mongoose = require('mongoose');
const User = require('./src/models/User');
const dotenv = require('dotenv');

dotenv.config();

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to DB');
    const users = await User.find();
    console.log('Total users:', users.length);
    console.log('Users:', users.map(u => ({ email: u.email, role: u.role, status: u.status, name: u.name })));
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
