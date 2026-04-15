const mongoose = require('mongoose');

const energyDailySummarySchema = new mongoose.Schema({
  deviceId: { type: String, required: true },
  deviceName: { type: String, required: true },
  location: { type: String, required: true },
  readingType: { type: String, enum: ['electricity', 'water', 'gas'], default: 'electricity' },
  date: { type: String, required: true }, // YYYY-MM-DD
  totalConsumption: { type: Number, default: 0 },
  peakHour: { type: Number, default: 0 }, // Hour with highest consumption
  peakValue: { type: Number, default: 0 },
  averageHourly: { type: Number, default: 0 },
  hourlyData: { type: Map, of: Number, default: {} }, // {"00": 2.5, "01": 1.8, ...}
  alerts: { type: Number, default: 0 },
}, {
  timestamps: true,
});

energyDailySummarySchema.index({ deviceId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('EnergyDailySummary', energyDailySummarySchema);