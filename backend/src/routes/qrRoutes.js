const express = require('express');
const router = express.Router();
const { getResidentQR } = require('../controllers/qrController');
const { protect } = require('../middleware/auth');
router.get('/my-qr', protect, getResidentQR);

module.exports = router;