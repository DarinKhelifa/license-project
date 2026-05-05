const ParkingReservation = require('../models/ParkingReservation');
const mongoose = require('mongoose');

// Configuration: number of parking spots and labels
const SPOT_COUNT = 12;
function buildSpotList() {
  const list = [];
  for (let i = 1; i <= SPOT_COUNT; i++) {
    list.push({ spotId: `P${i}`, label: `Spot ${i}` });
  }
  return list;
}

// Normalize date string (YYYY-MM-DD) -> Date object at UTC midnight
function parseDateOnly(dateStr) {
  if (!dateStr) return null;
  const parts = dateStr.split('-').map((p) => parseInt(p, 10));
  if (parts.length !== 3) return null;
  const [y, m, d] = parts;
  return new Date(Date.UTC(y, m - 1, d));
}

exports.getSlots = async (req, res) => {
  try {
    const dateStr = req.query.date || new Date().toISOString().split('T')[0];
    const date = parseDateOnly(dateStr);
    if (!date) return res.status(400).json({ message: 'Invalid date. Use YYYY-MM-DD' });

    const spots = buildSpotList();

    const reservations = await ParkingReservation.find({ date }).lean();
    const map = {};
    for (const r of reservations) map[r.spotId] = r;

    const result = spots.map((s) => ({
      spotId: s.spotId,
      label: s.label,
      reserved: !!map[s.spotId],
      reservation: map[s.spotId] ? {
        id: map[s.spotId]._id,
        userId: map[s.spotId].userId,
        userName: map[s.spotId].userName,
        createdAt: map[s.spotId].createdAt,
      } : null,
    }));

    return res.json({ date: dateStr, spots: result });
  } catch (error) {
    console.error('getSlots error', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.reserve = async (req, res) => {
  try {
    const { spotId, date: dateStr, userId, userName } = req.body;
    if (!spotId || !dateStr || !userId || !userName) {
      return res.status(400).json({ message: 'spotId, date, userId and userName are required' });
    }

    const date = parseDateOnly(dateStr);
    if (!date) return res.status(400).json({ message: 'Invalid date format. Use YYYY-MM-DD' });

    // Prevent user reserving more than one spot on same date
    const existingUserReservation = await ParkingReservation.findOne({ date, userId });
    if (existingUserReservation) {
      return res.status(409).json({ message: 'User already has a reservation for that date', reservation: existingUserReservation });
    }

    const reservation = new ParkingReservation({ spotId, date, userId: mongoose.Types.ObjectId(userId), userName });
    try {
      const saved = await reservation.save();
      return res.status(201).json({ message: 'Reserved', reservation: saved });
    } catch (err) {
      // Handle duplicate key (slot already reserved)
      if (err && err.code === 11000) {
        return res.status(409).json({ message: 'Spot already reserved for that date' });
      }
      throw err;
    }
  } catch (error) {
    console.error('reserve error', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.cancel = async (req, res) => {
  try {
    const id = req.params.id;
    const { userId } = req.body;
    if (!id) return res.status(400).json({ message: 'Reservation id required' });
    if (!userId) return res.status(400).json({ message: 'userId required in body to authorize cancellation' });

    const reservation = await ParkingReservation.findById(id);
    if (!reservation) return res.status(404).json({ message: 'Reservation not found' });

    if (reservation.userId.toString() !== userId.toString()) {
      return res.status(403).json({ message: 'You can only cancel your own reservations' });
    }

    await ParkingReservation.findByIdAndDelete(id);
    return res.json({ message: 'Cancelled' });
  } catch (error) {
    console.error('cancel error', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.listReservations = async (req, res) => {
  try {
    const dateStr = req.query.date;
    let filter = {};
    if (dateStr) {
      const date = parseDateOnly(dateStr);
      if (!date) return res.status(400).json({ message: 'Invalid date' });
      filter.date = date;
    }
    const reservations = await ParkingReservation.find(filter).sort({ date: -1, createdAt: -1 }).lean();
    return res.json({ reservations });
  } catch (error) {
    console.error('listReservations error', error);
    return res.status(500).json({ message: 'Server error' });
  }
};
