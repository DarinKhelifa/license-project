const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema({
  type: {
    type: String,
    default: 'FIRE'
  },
  sensor: {
    type: String,
    default: 'flame_sensor'
  },
  location: {
    type: String,
    default: 'Building'
  },
  status: {
    type: String,
    enum: ['active', 'resolved'],
    default: 'active'
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Alert', alertSchema);