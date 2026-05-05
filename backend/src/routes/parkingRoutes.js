const express = require('express');
const router = express.Router();
const parkingController = require('../controllers/parkingController');

// GET /api/parking/slots?date=YYYY-MM-DD
router.get('/slots', parkingController.getSlots);

// POST /api/parking/reserve
router.post('/reserve', parkingController.reserve);

// DELETE /api/parking/:id  (body must contain userId to authorize cancellation)
router.delete('/:id', parkingController.cancel);

// GET /api/parking/reservations?date=YYYY-MM-DD
router.get('/reservations', parkingController.listReservations);

module.exports = router;
