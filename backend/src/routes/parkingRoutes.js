const express = require('express');
const router = express.Router();
const parkingController = require('../controllers/parkingController');
const { protect, authorize } = require('../middleware/auth');

// Get parking lots for a residence
router.get('/:residenceId/lots', protect, parkingController.getParkingLots);

// Get parking lot details with spots
router.get('/:residenceId/lots/:parkingLotId', protect, parkingController.getParkingLotDetails);

// Create parking reservation (resident)
router.post('/reservations/create', protect, parkingController.createReservation);

// Get user's reservations
router.get('/my-reservations', protect, parkingController.getUserReservations);

// Get reservations for a residence (admin)
router.get('/:residenceId/reservations', protect, authorize('admin'), parkingController.getResidenceReservations);

// Approve reservation (admin)
router.put('/:residenceId/reservations/:reservationId/approve', protect, authorize('admin'), parkingController.approveReservation);

// Reject reservation (admin)
router.put('/:residenceId/reservations/:reservationId/reject', protect, authorize('admin'), parkingController.rejectReservation);

// Cancel reservation (resident)
router.delete('/reservations/:reservationId/cancel', protect, parkingController.cancelReservation);

module.exports = router;
