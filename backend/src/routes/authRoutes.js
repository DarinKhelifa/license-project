const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  register,
  login,
  getMe,
  updateProfile,
  changePassword,
  getAllUsers,
  updateUserRole,
  updateUserStatus,
  verifyOTP,
  resendOTP
} = require('../controllers/authController');

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);

// Protected routes
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.put('/change-password', protect, changePassword);

// Admin routes
router.get('/users', protect, authorize('admin'), getAllUsers);
router.put('/users/:id/role', protect, authorize('admin'), updateUserRole);
router.put('/users/:id/status', protect, authorize('admin'), updateUserStatus);

module.exports = router;