const mongoose = require('mongoose');

const buildingSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, trim: true },
    name: { type: String, required: true, trim: true },
    apartments: { type: Number, required: true, min: 1 },
  },
  { _id: false }
);

const parkingSpotSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, trim: true },
    code: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ['available', 'reserved', 'pending'],
      default: 'available',
      required: true,
    },
  },
  { _id: false }
);

const parkingLotSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, trim: true },
    name: { type: String, required: true, trim: true },
    totalSpots: { type: Number, required: true, min: 1 },
    spots: { type: [parkingSpotSchema], default: [] },
  },
  { _id: false }
);

const reservationSchema = new mongoose.Schema(
  {
    residentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    residentName: { type: String, required: true, trim: true },
    apartmentRef: { type: String, required: true, trim: true },
    buildingRef: { type: String, required: true, trim: true },
    parkingLotId: { type: String, required: true, trim: true },
    spotCode: { type: String, required: true, trim: true },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
      required: true,
    },
    createdAt: { type: Date, default: Date.now },
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    approvedAt: { type: Date, default: null },
  },
  { _id: true }
);

const residenceSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
    buildings: { type: [buildingSchema], default: [] },
    parkingSpots: { type: [parkingSpotSchema], default: [] },
    parkingLots: { type: [parkingLotSchema], default: [] },
    reservations: { type: [reservationSchema], default: [] },
  },
  { timestamps: true }
);

residenceSchema.index({ name: 1, address: 1 }, { unique: true });

module.exports = mongoose.model('Residence', residenceSchema);
