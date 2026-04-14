const mongoose = require('mongoose');

const postSchema = new mongoose.Schema({
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
  content: {
    type: String,
    required: true,
    maxlength: 5000,
  },
  imageUrls: [{
    type: String,
    default: '',
  }],
  attachmentUrls: [{
    type: String,
    default: '',
  }],
  likes: {
    type: Number,
    default: 0,
  },
  likedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  comments: {
    type: Number,
    default: 0,
  },
  shares: {
    type: Number,
    default: 0,
  },
  reactions: [{
    userId: mongoose.Schema.Types.ObjectId,
    emoji: String,
  }],
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Index for faster queries
postSchema.index({ createdAt: -1 });
postSchema.index({ userId: 1 });

module.exports = mongoose.model('Post', postSchema);
