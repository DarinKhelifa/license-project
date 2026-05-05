const express = require('express');
const router = express.Router();
const contactController = require('../controllers/contactController');

// Public: submit a contact message
router.post('/', contactController.createMessage);

// Admin: list messages
router.get('/', contactController.listMessages);

// Get single
router.get('/:id', contactController.getMessage);

// Update status
router.patch('/:id/status', contactController.updateStatus);

module.exports = router;
