const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  date: { type: Date, required: true },
  time: { type: String, required: true },
  location: { type: String, required: true },
  category: { 
    type: String, 
    enum: ['social', 'sports', 'educational', 'workshop', 'festival', 'other'],
    default: 'social'
  },
  imageBase64: { type: String },
  capacity: { type: Number, default: 0 },
  currentRegistrations: { type: Number, default: 0 },
  status: { 
    type: String, 
    enum: ['pending', 'approved', 'rejected', 'cancelled'],
    default: 'pending'
  },
  createdBy: { type: String, required: true },
  createdByName: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  approvedBy: { type: String },
  approvedAt: { type: Date },
  rejectionReason: { type: String },
  isActive: { type: Boolean, default: true },
}, {
  timestamps: true,
});

// Index for faster queries
eventSchema.index({ status: 1, date: 1 });
eventSchema.index({ createdBy: 1 });

module.exports = mongoose.model('Event', eventSchema);