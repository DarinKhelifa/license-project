const mongoose = require('mongoose');

const storySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  userName: {
    type: String,
    required: true,
  },
  userAvatar: {
    type: String,
    default: '',
  },
  imageUrl: {
    type: String,
    required: true,
  },
  viewedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  reactions: [{
    userId: mongoose.Schema.Types.ObjectId,
    emoji: String,
  }],
  createdAt: {
    type: Date,
    default: Date.now,
  },
  expiresAt: {
    type: Date,
    default: () => new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours from now
    index: { expireAfterSeconds: 0 }, // TTL index for automatic deletion
  },
});

// Index for faster queries
storySchema.index({ userId: 1, createdAt: -1 });
storySchema.index({ createdAt: -1 });

module.exports = mongoose.model('Story', storySchema);
