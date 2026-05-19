const mongoose = require('mongoose');

const parkingReservationSchema = new mongoose.Schema({
  residenceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Residence',
    required: true,
  },
  parkingLotId: {
    type: String,
    required: true,
    trim: true,
  },
  spotCode: {
    type: String,
    required: true,
    trim: true,
  },
  residentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  residentName: {
    type: String,
    required: true,
    trim: true,
  },
  apartmentRef: {
    type: String,
    required: true,
    trim: true,
  },
  startDate: {
    type: Date,
    required: true,
  },
  endDate: {
    type: Date,
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  approvedAt: {
    type: Date,
    default: null,
  },
  rejectionReason: {
    type: String,
    default: null,
  },
});

// Prevent overlapping reservations
parkingReservationSchema.index({ residenceId: 1, parkingLotId: 1, spotCode: 1, startDate: 1, endDate: 1 });
parkingReservationSchema.index({ residentId: 1 });
parkingReservationSchema.index({ residenceId: 1 });
parkingReservationSchema.index({ status: 1 });

module.exports = mongoose.model('ParkingReservation', parkingReservationSchema);
