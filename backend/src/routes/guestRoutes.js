const express = require('express');
const router = express.Router();
const {
    generateGuestQR,
    getMyGuests,
    getGuestQR,
} = require('../controllers/guestController');

// Generate QR + save to DB
router.post('/generate', generateGuestQR);

// Get all guests for a resident
router.get('/resident/:residentId', getMyGuests);

// Get single guest QR
router.get('/:guestId', getGuestQR);

module.exports = router;