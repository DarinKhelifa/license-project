const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { getCurrentReadings } = require('../controllers/environmentController');

router.get('/current', protect, getCurrentReadings);

module.exports = router;
