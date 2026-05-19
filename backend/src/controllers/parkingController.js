const Residence = require('../models/Residence');
const ParkingReservation = require('../models/ParkingReservation');
const User = require('../models/User');

function mapSpot(spot) {
  return {
    id: spot.id,
    code: spot.code,
    status: spot.status || 'available',
  };
}

function buildLegacyParkingLot(residence) {
  const legacySpots = Array.isArray(residence.parkingSpots) ? residence.parkingSpots : [];
  if (legacySpots.length === 0) return null;

  return {
    id: `${residence._id}-lot-01`,
    name: 'Parking 1',
    totalSpots: legacySpots.length,
    spots: legacySpots.map(mapSpot),
  };
}

async function getNormalizedParkingLots(residence) {
  const existingLots = Array.isArray(residence.parkingLots) ? residence.parkingLots.filter((lot) => lot && lot.id) : [];
  if (existingLots.length > 0 && existingLots.some((lot) => Array.isArray(lot.spots) && lot.spots.length > 0)) {
    return existingLots.map((lot) => ({
      id: lot.id,
      name: lot.name,
      totalSpots: lot.totalSpots,
      spots: Array.isArray(lot.spots) ? lot.spots.map(mapSpot) : [],
    }));
  }

  const legacyLot = buildLegacyParkingLot(residence);
  if (legacyLot) {
    residence.parkingLots = [legacyLot];
    await residence.save();
    return [legacyLot];
  }

  return [];
}

// ========== GET PARKING LOTS FOR RESIDENCE ==========
const getParkingLots = async (req, res) => {
  try {
    const { residenceId } = req.params;

    const residence = await Residence.findById(residenceId);
    if (!residence) {
      return res.status(404).json({ message: 'Residence not found' });
    }

    const parkingLots = await getNormalizedParkingLots(residence);

    res.json({
      residenceId: residence._id,
      residenceName: residence.name,
      parkingLots,
    });
  } catch (error) {
    console.error('Get parking lots error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== GET PARKING LOT DETAILS WITH SLOTS ==========
const getParkingLotDetails = async (req, res) => {
  try {
    const { residenceId, parkingLotId } = req.params;

    const residence = await Residence.findById(residenceId);
    if (!residence) {
      return res.status(404).json({ message: 'Residence not found' });
    }

    const parkingLots = await getNormalizedParkingLots(residence);
    const parkingLot = parkingLots.find(
      (lot) => lot.id === parkingLotId
    );
    if (!parkingLot) {
      return res.status(404).json({ message: 'Parking lot not found' });
    }

    // Get all active reservations for this parking lot
    const reservations = await ParkingReservation.find({
      residenceId,
      parkingLotId,
      status: { $in: ['pending', 'approved'] },
    }).lean();

    // Map reserved spots
    const reservedSpots = {};
    reservations.forEach((res) => {
      reservedSpots[res.spotCode] = {
        status: res.status,
        residentName: res.residentName,
        startDate: res.startDate,
        endDate: res.endDate,
        reservationId: res._id,
      };
    });

    // Build spot details with reservation info
    const spotsWithDetails = parkingLot.spots.map((spot) => ({
      id: spot.id,
      code: spot.code,
      status: spot.status,
      reservation: reservedSpots[spot.code] || null,
    }));

    res.json({
      residenceId,
      parkingLot: {
        id: parkingLot.id,
        name: parkingLot.name,
        totalSpots: parkingLot.totalSpots,
        spots: spotsWithDetails,
      },
    });
  } catch (error) {
    console.error('Get parking lot details error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== CREATE PARKING RESERVATION (Resident) ==========
const createReservation = async (req, res) => {
  try {
    const { residenceId, parkingLotId, spotCode, startDate, endDate } =
      req.body;
    const userId = req.user.id;

    if (!residenceId || !parkingLotId || !spotCode || !startDate || !endDate) {
      return res
        .status(400)
        .json({ message: 'Missing required fields' });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (start >= end) {
      return res
        .status(400)
        .json({ message: 'End date must be after start date' });
    }

    // Get residence
    const residence = await Residence.findById(residenceId);
    if (!residence) {
      return res.status(404).json({ message: 'Residence not found' });
    }

    // Verify parking lot exists
    const parkingLots = await getNormalizedParkingLots(residence);
    const parkingLot = parkingLots.find(
      (lot) => lot.id === parkingLotId
    );
    if (!parkingLot) {
      return res.status(404).json({ message: 'Parking lot not found' });
    }

    // Verify spot exists
    const spot = parkingLot.spots.find((s) => s.code === spotCode);
    if (!spot) {
      return res.status(404).json({ message: 'Parking spot not found' });
    }

    // Check for overlapping reservations
    const overlapping = await ParkingReservation.findOne({
      residenceId,
      parkingLotId,
      spotCode,
      status: { $in: ['pending', 'approved'] },
      $or: [
        { startDate: { $lt: end }, endDate: { $gt: start } },
      ],
    });

    if (overlapping) {
      return res
        .status(400)
        .json({ message: 'Spot already reserved for these dates' });
    }

    // Get user details
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Create reservation
    const reservation = new ParkingReservation({
      residenceId,
      parkingLotId,
      spotCode,
      residentId: userId,
      residentName: user.name,
      apartmentRef: user.apartment || '',
      startDate: start,
      endDate: end,
      status: 'pending',
    });

    await reservation.save();

    res.status(201).json({
      success: true,
      message: 'Reservation created. Pending admin approval.',
      reservation: {
        _id: reservation._id,
        spotCode: reservation.spotCode,
        startDate: reservation.startDate,
        endDate: reservation.endDate,
        status: reservation.status,
      },
    });
  } catch (error) {
    console.error('Create reservation error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== GET USER'S RESERVATIONS ==========
const getUserReservations = async (req, res) => {
  try {
    const userId = req.user.id;

    const reservations = await ParkingReservation.find({
      residentId: userId,
    })
      .populate('residenceId', 'name address')
      .sort({ createdAt: -1 });

    res.json(reservations);
  } catch (error) {
    console.error('Get user reservations error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== GET RESERVATIONS FOR RESIDENCE (Admin) ==========
const getResidenceReservations = async (req, res) => {
  try {
    const { residenceId } = req.params;

    const residence = await Residence.findById(residenceId);
    if (!residence) {
      return res.status(404).json({ message: 'Residence not found' });
    }

    const reservations = await ParkingReservation.find({ residenceId })
      .populate('residentId', 'name email apartment')
      .populate('approvedBy', 'name')
      .sort({ createdAt: -1 });

    res.json(reservations);
  } catch (error) {
    console.error('Get residence reservations error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== APPROVE RESERVATION (Admin) ==========
const approveReservation = async (req, res) => {
  try {
    const { reservationId } = req.params;
    const adminId = req.user.id;

    const reservation = await ParkingReservation.findById(reservationId);
    if (!reservation) {
      return res.status(404).json({ message: 'Reservation not found' });
    }

    if (reservation.status !== 'pending') {
      return res
        .status(400)
        .json({ message: 'Only pending reservations can be approved' });
    }

    // Update reservation
    reservation.status = 'approved';
    reservation.approvedBy = adminId;
    reservation.approvedAt = new Date();
    await reservation.save();

    // Update spot status in residence
    const residence = await Residence.findById(reservation.residenceId);
    if (residence) {
      const parkingLots = await getNormalizedParkingLots(residence);
      const parkingLot = parkingLots.find(
        (lot) => lot.id === reservation.parkingLotId
      );
      if (parkingLot) {
        const spot = parkingLot.spots.find((s) => s.code === reservation.spotCode);
        if (spot) {
          spot.status = 'reserved';
          const legacySpot = Array.isArray(residence.parkingSpots)
            ? residence.parkingSpots.find((item) => item.code === reservation.spotCode)
            : null;
          if (legacySpot) {
            legacySpot.status = 'reserved';
          }
          residence.parkingLots = parkingLots;
          await residence.save();
        }
      }
    }

    res.json({
      success: true,
      message: 'Reservation approved',
      reservation,
    });
  } catch (error) {
    console.error('Approve reservation error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== REJECT RESERVATION (Admin) ==========
const rejectReservation = async (req, res) => {
  try {
    const { reservationId } = req.params;
    const { rejectionReason } = req.body;

    const reservation = await ParkingReservation.findById(reservationId);
    if (!reservation) {
      return res.status(404).json({ message: 'Reservation not found' });
    }

    if (reservation.status !== 'pending') {
      return res
        .status(400)
        .json({ message: 'Only pending reservations can be rejected' });
    }

    reservation.status = 'rejected';
    reservation.rejectionReason = rejectionReason || null;
    await reservation.save();

    res.json({
      success: true,
      message: 'Reservation rejected',
      reservation,
    });
  } catch (error) {
    console.error('Reject reservation error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== CANCEL RESERVATION (Resident) ==========
const cancelReservation = async (req, res) => {
  try {
    const { reservationId } = req.params;
    const userId = req.user.id;

    const reservation = await ParkingReservation.findById(reservationId);
    if (!reservation) {
      return res.status(404).json({ message: 'Reservation not found' });
    }

    if (reservation.residentId.toString() !== userId) {
      return res
        .status(403)
        .json({ message: 'You can only cancel your own reservations' });
    }

    if (reservation.status === 'rejected') {
      return res
        .status(400)
        .json({ message: 'Cannot cancel rejected reservations' });
    }

    // If already approved, revert spot status
    if (reservation.status === 'approved') {
      const residence = await Residence.findById(reservation.residenceId);
      if (residence) {
        const parkingLots = await getNormalizedParkingLots(residence);
        const parkingLot = parkingLots.find(
          (lot) => lot.id === reservation.parkingLotId
        );
        if (parkingLot) {
          const spot = parkingLot.spots.find(
            (s) => s.code === reservation.spotCode
          );
          if (spot) {
            spot.status = 'available';
            const legacySpot = Array.isArray(residence.parkingSpots)
              ? residence.parkingSpots.find((item) => item.code === reservation.spotCode)
              : null;
            if (legacySpot) {
              legacySpot.status = 'available';
            }
            residence.parkingLots = parkingLots;
            await residence.save();
          }
        }
      }
    }

    await ParkingReservation.findByIdAndDelete(reservationId);

    res.json({
      success: true,
      message: 'Reservation cancelled',
    });
  } catch (error) {
    console.error('Cancel reservation error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getParkingLots,
  getParkingLotDetails,
  createReservation,
  getUserReservations,
  getResidenceReservations,
  approveReservation,
  rejectReservation,
  cancelReservation,
};
