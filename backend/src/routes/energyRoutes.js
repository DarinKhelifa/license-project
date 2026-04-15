const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getCurrentReadings,
  getHistoricalData,
  getDeviceSummary,
} = require('../controllers/energyController');

router.get('/current', protect, getCurrentReadings);
router.get('/historical', protect, getHistoricalData);
router.get('/device/:deviceId/summary', protect, getDeviceSummary);

module.exports = router;