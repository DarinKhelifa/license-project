const SecurityNote = require('../models/SecurityNote');

const normalizeNote = (note) => ({
  _id: note._id,
  id: note._id.toString(),
  userId: note.userId,
  title: note.title ?? '',
  content: note.content ?? '',
  reminder: note.reminder ?? null,
  createdAt: note.createdAt,
  updatedAt: note.updatedAt,
});

const getMyNotes = async (req, res) => {
  try {
    const notes = await SecurityNote.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.json(notes.map(normalizeNote));
  } catch (error) {
    console.error('Get security notes error:', error);
    res.status(500).json({ message: error.message });
  }
};

const createNote = async (req, res) => {
  try {
    const title = (req.body.title ?? '').toString().trim();
    const content = (req.body.content ?? '').toString().trim();
    const reminder = req.body.reminder ? new Date(req.body.reminder) : null;

    if (!title && !content) {
      return res.status(400).json({ message: 'Title or content is required' });
    }

    const note = await SecurityNote.create({
      userId: req.user.id,
      title,
      content,
      reminder: reminder && !Number.isNaN(reminder.getTime()) ? reminder : null,
    });

    res.status(201).json(normalizeNote(note));
  } catch (error) {
    console.error('Create security note error:', error);
    res.status(500).json({ message: error.message });
  }
};

const updateNote = async (req, res) => {
  try {
    const note = await SecurityNote.findOne({ _id: req.params.id, userId: req.user.id });

    if (!note) {
      return res.status(404).json({ message: 'Note not found' });
    }

    if (req.body.title !== undefined) {
      note.title = req.body.title.toString().trim();
    }
    if (req.body.content !== undefined) {
      note.content = req.body.content.toString().trim();
    }
    if (req.body.reminder !== undefined) {
      if (req.body.reminder) {
        const reminder = new Date(req.body.reminder);
        note.reminder = Number.isNaN(reminder.getTime()) ? null : reminder;
      } else {
        note.reminder = null;
      }
    }

    if (!note.title && !note.content) {
      return res.status(400).json({ message: 'Title or content is required' });
    }

    await note.save();
    res.json(normalizeNote(note));
  } catch (error) {
    console.error('Update security note error:', error);
    res.status(500).json({ message: error.message });
  }
};

const deleteNote = async (req, res) => {
  try {
    const note = await SecurityNote.findOneAndDelete({ _id: req.params.id, userId: req.user.id });

    if (!note) {
      return res.status(404).json({ message: 'Note not found' });
    }

    res.json({ message: 'Note deleted successfully' });
  } catch (error) {
    console.error('Delete security note error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getMyNotes,
  createNote,
  updateNote,
  deleteNote,
};