const mongoose = require('mongoose');

const securityNoteSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  title: { type: String, default: '' },
  content: { type: String, default: '' },
  reminder: { type: Date },
}, {
  timestamps: true,
});

securityNoteSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('SecurityNote', securityNoteSchema);