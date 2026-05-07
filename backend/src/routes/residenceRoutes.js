const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const residenceController = require('../controllers/residenceController');
// Public: allow read-only access to residences for signup and public listing
router.get('/', residenceController.getResidences);

// Admin-only routes
router.post('/', protect, authorize('admin'), residenceController.createResidence);
router.post('/:id/buildings', protect, authorize('admin'), residenceController.addBuilding);
router.post('/:id/parking-spots', protect, authorize('admin'), residenceController.addParkingSpots);
router.post('/:id/reservations', protect, authorize('admin'), residenceController.createReservation);
router.patch('/:id/reservations/:reservationId', protect, authorize('admin'), residenceController.updateReservationStatus);

module.exports = router;
