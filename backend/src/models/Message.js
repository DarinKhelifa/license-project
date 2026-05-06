const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  chatId: { type: String, required: true, index: true },
  senderId: { type: String, required: true },
  senderName: { type: String, required: true },
  text: { type: String, required: true },
  type: { type: String, enum: ['text', 'image', 'file', 'audio'], default: 'text' },
  mediaUrl: { type: String },
  status: { type: String, enum: ['sent', 'delivered', 'read'], default: 'sent' },
  readBy: [{ type: String }],
  replyTo: { type: String },
  deleted: { type: Boolean, default: false },
  is_edited: { type: Boolean, default: false },
  is_deleted: { type: Boolean, default: false },
}, {
  timestamps: true,
});

// Index for faster queries
messageSchema.index({ chatId: 1, createdAt: -1 });

module.exports = mongoose.model('Message', messageSchema);