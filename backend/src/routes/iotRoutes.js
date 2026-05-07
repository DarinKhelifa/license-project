const express = require('express');
const router = express.Router();
const Alert = require('../models/Alert');

// ESP8266 sends fire alert here
router.post('/fire', async (req, res) => {
  console.log('🔥 FIRE ALERT RECEIVED from ESP8266');

  try {
    // Save to MongoDB
    const alert = await Alert.create({
      type: 'FIRE',
      sensor: 'flame_sensor',
      location: 'Building',
      status: 'active'
    });

    console.log('Alert saved:', alert);

    res.status(200).json({
      success: true,
      message: 'Fire alert saved',
      alert
    });

  } catch (error) {
    console.error('Error saving alert:', error);
    res.status(500).json({ success: false });
  }
});

// Dashboard fetches alerts here
router.get('/alerts', async (req, res) => {
  try {
    const alerts = await Alert.find()
      .sort({ timestamp: -1 }) // newest first
      .limit(50);

    res.status(200).json({ success: true, alerts });

  } catch (error) {
    res.status(500).json({ success: false });
  }
});

// Resolve an alert
router.put('/alerts/:id/resolve', async (req, res) => {
  try {
    const alert = await Alert.findByIdAndUpdate(
      req.params.id,
      { status: 'resolved' },
      { new: true }
    );

    res.status(200).json({ success: true, alert });

  } catch (error) {
    res.status(500).json({ success: false });
  }
});

module.exports = router;