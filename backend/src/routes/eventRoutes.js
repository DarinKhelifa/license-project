const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  createEvent,
  getAllEvents,
  getEventById,
  getMyEvents,
  updateEvent,
  cancelEvent,
  getPendingEvents,
  getAllEventsAdmin,
  approveEvent,
  rejectEvent,
  deleteEvent,
} = require('../controllers/eventController');

// Admin only routes (MUST BE BEFORE /:id routes)
router.get('/admin/pending', protect, authorize('admin'), getPendingEvents);
router.get('/admin/all', protect, authorize('admin'), getAllEventsAdmin);
router.put('/admin/:id/approve', protect, authorize('admin'), approveEvent);
router.put('/admin/:id/reject', protect, authorize('admin'), rejectEvent);
router.delete('/admin/:id', protect, authorize('admin'), deleteEvent);

// Public routes (authenticated users) - MUST BE AFTER /admin routes
router.get('/my-events', protect, getMyEvents);
router.get('/', protect, getAllEvents);
router.get('/:id', protect, getEventById);
router.post('/', protect, createEvent);
router.put('/:id', protect, updateEvent);
router.delete('/:id', protect, cancelEvent);

module.exports = router;