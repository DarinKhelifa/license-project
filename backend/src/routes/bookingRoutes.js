const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  createBooking,
  getUserBookings,
  getAvailableSlots,
  cancelBooking,
} = require('../controllers/bookingController');

// Protected routes (require authentication)
router.post('/', protect, createBooking);
router.get('/my-bookings', protect, getUserBookings);
router.put('/:bookingId/cancel', protect, cancelBooking);

// Public route (can check availability without auth)
router.get('/availability/:facilityId', getAvailableSlots);

module.exports = router;
