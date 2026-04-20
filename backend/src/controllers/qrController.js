const User = require('../models/User');
const jwt = require('jsonwebtoken');

// @desc    Get resident QR code
// @route   GET /api/qr/my-qr
// @access  Private (resident only)
const getResidentQR = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select('name apartment qrToken status role');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.status !== 'active') {
      return res.status(403).json({ message: 'Account not approved yet' });
    }

    if (!user.qrToken) {
      return res.status(404).json({ message: 'QR not generated yet' });
    }

    const decoded = jwt.decode(user.qrToken);

    return res.status(200).json({
      success: true,
      qrToken: user.qrToken,
      resident: {
        userId: decoded.userId,
        name: decoded.name,
        apartment: decoded.apartment,
      },
    });

  } catch (error) {
    console.error('Get QR error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getResidentQR };