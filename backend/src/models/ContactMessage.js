const mongoose = require('mongoose');

const contactMessageSchema = new mongoose.Schema({
  name: { type: String },
  email: { type: String, required: true, index: true },
  phone: { type: String },
  subject: { type: String },
  message: { type: String, required: true },
  status: { type: String, enum: ['new', 'read', 'closed'], default: 'new' },
}, {
  timestamps: true,
});

contactMessageSchema.index({ createdAt: -1 });

module.exports = mongoose.model('ContactMessage', contactMessageSchema);
