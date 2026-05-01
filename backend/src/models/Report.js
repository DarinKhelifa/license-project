const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  category: { type: String, required: true, enum: ['security', 'maintenance', 'noise', 'other'] },
  subCategory: { 
    type: String, 
    required: true, 
    enum: [
      'theft','suspicious','assault',
      'plumbing','electrical','pest','structural',
      'loud_music','party','construction',
      'other'
    ]
  },
  location: { type: String, required: true },
  description: { type: String, required: false },
  photoBase64: { type: String },
  timeIsNow: { type: Boolean, default: true },
  customTime: { type: String },
  status: { 
    type: String, 
    enum: ['pending', 'in-progress', 'resolved', 'rejected'],
    default: 'pending'
  },
  createdBy: { type: String, required: true },
  createdByName: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  resolvedAt: { type: Date },
  resolvedBy: { type: String },
  resolutionNotes: { type: String },
}, {
  timestamps: true,
});

// Index for faster queries
reportSchema.index({ status: 1, createdAt: -1 });
reportSchema.index({ createdBy: 1 });

module.exports = mongoose.model('Report', reportSchema);