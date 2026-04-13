const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  createBooking,
  getUserBookings,
  getAvailableSlots,
  cancelBooking,
  getPendingBookings,
  getBookingHistory,
  approveBooking,
  rejectBooking,
} = require('../controllers/bookingController');

// Protected routes (require authentication)
router.post('/', protect, createBooking);
router.get('/my-bookings', protect, getUserBookings);
router.put('/:bookingId/cancel', protect, cancelBooking);

// Facilities Manager routes
router.get('/manager/pending', protect, getPendingBookings);
router.get('/manager/history', protect, getBookingHistory);
router.put('/:bookingId/approve', protect, approveBooking);
router.put('/:bookingId/reject', protect, rejectBooking);

// Public route (can check availability without auth)
router.get('/availability/:facilityId', getAvailableSlots);

module.exports = router;
