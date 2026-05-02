const mongoose = require('mongoose');

const environmentReadingSchema = new mongoose.Schema({
  deviceId: { type: String, required: true },
  deviceName: { type: String, required: true },
  location: { type: String, required: true },
  temperature: { type: Number, required: true },
  humidity: { type: Number, required: true },
  unitTemp: { type: String, default: '°C' },
  unitHum: { type: String, default: '%' },
  timestamp: { type: Date, default: Date.now },
  isAlert: { type: Boolean, default: false },
}, {
  timestamps: true,
});

environmentReadingSchema.index({ deviceId: 1, timestamp: -1 });
environmentReadingSchema.index({ location: 1, timestamp: -1 });

module.exports = mongoose.model('EnvironmentReading', environmentReadingSchema);
