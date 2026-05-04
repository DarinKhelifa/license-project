const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const settingsController = require('../controllers/settingsController');

router.get('/me', protect, settingsController.getSettings);
router.put('/appearance', protect, settingsController.updateAppearance);
router.put('/notifications', protect, settingsController.updateNotifications);
router.put('/security', protect, settingsController.updateSecurity);

module.exports = router;
