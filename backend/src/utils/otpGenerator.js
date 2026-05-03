const crypto = require('crypto');

const generateOTP = () => {
  // Generate a 6-digit cryptographically secure OTP
  return crypto.randomInt(100000, 999999).toString();
};

module.exports = generateOTP;