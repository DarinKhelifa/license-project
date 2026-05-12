const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  getMyNotes,
  createNote,
  updateNote,
  deleteNote,
} = require('../controllers/securityNoteController');

router.get('/', protect, authorize('security', 'admin'), getMyNotes);
router.post('/', protect, authorize('security', 'admin'), createNote);
router.put('/:id', protect, authorize('security', 'admin'), updateNote);
router.delete('/:id', protect, authorize('security', 'admin'), deleteNote);

module.exports = router;