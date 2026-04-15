const mongoose = require('mongoose');

const energyReadingSchema = new mongoose.Schema({
  deviceId: { type: String, required: true },
  deviceName: { type: String, required: true },
  location: { type: String, required: true }, // e.g., "Building A", "Apartment B12"
  readingType: { type: String, enum: ['electricity', 'water', 'gas'], default: 'electricity' },
  value: { type: Number, required: true }, // kWh, liters, m3
  unit: { type: String, default: 'kWh' },
  timestamp: { type: Date, default: Date.now },
  isAlert: { type: Boolean, default: false },
  alertThreshold: { type: Number },
}, {
  timestamps: true,
});

// Index for efficient queries
energyReadingSchema.index({ deviceId: 1, timestamp: -1 });
energyReadingSchema.index({ location: 1, timestamp: -1 });

module.exports = mongoose.model('EnergyReading', energyReadingSchema);