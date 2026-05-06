const mongoose = require('mongoose');
const Message = require('../models/Message');

function deletedMessagesCollection() {
  return mongoose.connection.collection('user_deleted_messages');
}

async function editMessage(req, res) {
  try {
    const { id } = req.params;
    const { content } = req.body;

    const message = await Message.findById(id);
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }

    if (message.senderId !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to edit this message' });
    }

    const nextContent = (content || '').toString().trim();
    if (!nextContent) {
      return res.status(400).json({ message: 'Content is required' });
    }

    message.text = nextContent;
    message.is_edited = true;
    message.updatedAt = new Date();
    await message.save();

    const payload = {
      messageId: message._id.toString(),
      content: message.text,
      is_edited: true,
    };

    const io = req.app.get('io');
    if (io) {
      io.emit('message:updated', payload);
      io.emit('message-updated', payload);
    }

    res.json(payload);
  } catch (error) {
    console.error('Edit message error:', error);
    res.status(500).json({ message: error.message });
  }
}

async function deleteMessage(req, res) {
  try {
    const { id } = req.params;
    const scope = (req.query.scope || 'me').toString();

    const message = await Message.findById(id);
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }

    if (scope === 'everyone') {
      if (message.senderId !== req.user.id) {
        return res.status(403).json({ message: 'Not authorized to delete this message for everyone' });
      }

      message.is_deleted = true;
      message.updatedAt = new Date();
      await message.save();

      const payload = {
        messageId: message._id.toString(),
        is_deleted: true,
        content: 'This message was deleted',
      };

      const io = req.app.get('io');
      if (io) {
        io.emit('message:deleted', payload);
        io.emit('message-deleted', payload);
      }

      return res.json(payload);
    }

    await deletedMessagesCollection().updateOne(
      {
        user_id: req.user.id,
        message_id: message._id.toString(),
      },
      {
        $setOnInsert: {
          user_id: req.user.id,
          message_id: message._id.toString(),
          deleted_at: new Date(),
        },
      },
      { upsert: true }
    );

    res.json({
      messageId: message._id.toString(),
      scope: 'me',
    });
  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({ message: error.message });
  }
}

module.exports = {
  editMessage,
  deleteMessage,
};