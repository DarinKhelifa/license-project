const mongoose = require('mongoose');

const parkingReservationSchema = new mongoose.Schema({
  spotId: {
    type: String,
    required: true,
    trim: true,
  },
  date: {
    // store as date at midnight UTC for normalization
    type: Date,
    required: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  userName: {
    type: String,
    required: true,
    trim: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Unique index to prevent double-reserving the same spot on the same date
parkingReservationSchema.index({ spotId: 1, date: 1 }, { unique: true });
// Index to quickly find reservations by date or user
parkingReservationSchema.index({ date: 1 });
parkingReservationSchema.index({ userId: 1 });

module.exports = mongoose.model('ParkingReservation', parkingReservationSchema);
