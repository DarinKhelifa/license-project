const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  participants: [{ type: String, required: true }],
  participantNames: [{ type: String, required: true }],
  participantAvatars: [{ type: String }],
  lastMessage: { type: String, default: '' },
  lastMessageTime: { type: Date, default: Date.now },
  lastMessageSenderId: { type: String },
  unreadCount: { type: Map, of: Number, default: {} },
  type: { type: String, enum: ['private', 'group'], default: 'private' },
  groupName: { type: String },
  groupIcon: { type: String },
  createdBy: { type: String },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Chat', chatSchema);