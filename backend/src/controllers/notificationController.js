const Notification = require('../models/Notification');

// @desc    Create a notification
// @route   POST /api/notifications
const createNotification = async (req, res) => {
  try {
    const { userId, title, message, type, data } = req.body;

    if (!userId || !title || !message) {
      return res.status(400).json({
        success: false,
        error: 'userId, title, and message are required'
      });
    }

    const notification = new Notification({
      userId,
      title,
      message,
      type: type || 'general',
      data: data || {},
      isRead: false,
      createdAt: new Date()
    });

    await notification.save();

    res.status(201).json({ success: true, notification });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// @desc    Get all notifications for a user
// @route   GET /api/notifications/:userId
const getNotifications = async (req, res) => {
  try {
    const { userId } = req.params;

    const notifications = await Notification.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    res.json({ success: true, notifications });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// @desc    Mark one notification as read
// @route   PATCH /api/notifications/:id/read
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;

    const notification = await Notification.findByIdAndUpdate(
      id,
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ success: false, error: 'Notification not found' });
    }

    res.json({ success: true, notification });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// @desc    Mark all notifications as read for a user
// @route   PATCH /api/notifications/read-all/:userId
const markAllAsRead = async (req, res) => {
  try {
    const { userId } = req.params;

    await Notification.updateMany(
      { userId, isRead: false },
      { isRead: true }
    );

    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// @desc    Delete one notification
// @route   DELETE /api/notifications/:id
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;

    const notification = await Notification.findByIdAndDelete(id);

    if (!notification) {
      return res.status(404).json({ success: false, error: 'Notification not found' });
    }

    res.json({ success: true, message: 'Notification deleted successfully' });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

module.exports = {
  createNotification,
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification
};
