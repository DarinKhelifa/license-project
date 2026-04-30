const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['staff_added', 'event_approved', 'message_received'],
    required: true
  },
  title: {
    type: String,
    required: true
  },
  body: {
    type: String,
    required: true
  },
  isRead: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  // Optional metadata for different notification types
  metadata: {
    staffName: String,
    staffRole: String,
    eventTitle: String,
    eventDate: Date,
    eventLocation: String,
    senderName: String,
    senderPreview: String,
    messageId: mongoose.Schema.Types.ObjectId
  }
}, {
  timestamps: true
});

// Index for faster queries
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
