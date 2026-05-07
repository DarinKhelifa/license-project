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
      enum: ['available', 'reserved'],
      default: 'available',
      required: true,
    },
  },
  { _id: false }
);

const reservationSchema = new mongoose.Schema(
  {
    residentName: { type: String, required: true, trim: true },
    apartmentRef: { type: String, required: true, trim: true },
    buildingRef: { type: String, required: true, trim: true },
    spotCode: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ['pending', 'approved', 'denied'],
      default: 'pending',
      required: true,
    },
    createdAt: { type: Date, default: Date.now },
  },
  { _id: true }
);

const residenceSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
    buildings: { type: [buildingSchema], default: [] },
    parkingSpots: { type: [parkingSpotSchema], default: [] },
    reservations: { type: [reservationSchema], default: [] },
  },
  { timestamps: true }
);

residenceSchema.index({ name: 1, address: 1 }, { unique: true });

module.exports = mongoose.model('Residence', residenceSchema);
