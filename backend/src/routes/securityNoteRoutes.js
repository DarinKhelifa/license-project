const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  getMyNotes,
  createNote,
  updateNote,
  deleteNote,
} = require('../controllers/securityNoteController');

router.get('/', protect, authorize('security', 'admin', 'maintenance'), getMyNotes);
router.post('/', protect, authorize('security', 'admin', 'maintenance'), createNote);
router.put('/:id', protect, authorize('security', 'admin', 'maintenance'), updateNote);
router.delete('/:id', protect, authorize('security', 'admin', 'maintenance'), deleteNote);

module.exports = router;