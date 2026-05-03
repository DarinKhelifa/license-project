const express = require('express');
const { 
  createNotification,
  getNotifications, 
  markAsRead, 
  markAllAsRead, 
  deleteNotification 
} = require('../controllers/notificationController');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All routes are protected (require authentication)

// @route   POST /api/notifications
router.post('/', protect, createNotification);

// @route   PATCH /api/notifications/read-all/:userId
// MUST BE FIRST to avoid matching /:id/read
router.patch('/read-all/:userId', protect, markAllAsRead);

// @route   PATCH /api/notifications/:id/read
router.patch('/:id/read', protect, markAsRead);

// @route   DELETE /api/notifications/:id
router.delete('/:id', protect, deleteNotification);

// @route   GET /api/notifications/:userId
// MUST BE LAST (most generic route)
router.get('/:userId', protect, getNotifications);

module.exports = router;
