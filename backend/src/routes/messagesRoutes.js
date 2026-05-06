const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { editMessage, deleteMessage } = require('../controllers/messageActionsController');

router.patch('/:id', protect, editMessage);
router.delete('/:id', protect, deleteMessage);

module.exports = router;