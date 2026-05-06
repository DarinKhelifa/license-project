const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const upload = require('../middleware/upload');
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');

// Get all chats for a user
router.get('/chats', protect, async (req, res) => {
  try {
    const chats = await Chat.find({
      participants: req.user.id,
    }).sort({ lastMessageTime: -1 });

    // Enrich chats with participantAvatars using User.profileImage
    const mapped = await Promise.all(chats.map(async (chat) => {
      const avatars = [];
      for (const pid of chat.participants) {
        try {
          const u = await User.findById(pid).select('profileImage');
          avatars.push(u ? u.profileImage || '' : '');
        } catch (_) {
          avatars.push('');
        }
      }

      return {
        _id: chat._id,
        participants: chat.participants,
        participantNames: chat.participantNames,
        participantAvatars: avatars,
        lastMessage: chat.lastMessage,
        lastMessageTime: chat.lastMessageTime,
        lastMessageSenderId: chat.lastMessageSenderId,
        unreadCount: chat.unreadCount,
        type: chat.type,
        groupName: chat.groupName,
        groupIcon: chat.groupIcon,
        createdAt: chat.createdAt,
        updatedAt: chat.updatedAt,
      };
    }));

    res.json(mapped);
  } catch (error) {
    console.error('Get chats error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get messages for a specific chat
router.get('/chats/:chatId/messages', protect, async (req, res) => {
  try {
    const messages = await Message.find({
      chatId: req.params.chatId,
    }).sort({ createdAt: 1 });
    
    res.json(messages);
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Upload chat media (image/file). Returns a URL that can be sent over socket in a message.
router.post('/chats/:chatId/media', protect, upload.single('file'), async (req, res) => {
  try {
    const { chatId } = req.params;

    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ message: 'Chat not found' });
    }

    if (!chat.participants.includes(req.user.id)) {
      return res.status(403).json({ message: 'Not authorized for this chat' });
    }

    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const mediaUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    const mime = (req.file.mimetype || '');
    const type = mime.startsWith('image/') ? 'image' : mime.startsWith('audio/') ? 'audio' : 'file';

    res.json({
      mediaUrl,
      type,
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
      size: req.file.size,
    });
  } catch (error) {
    console.error('Upload chat media error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Create a new private chat
router.post('/chats', protect, async (req, res) => {
  try {
    const { otherUserId, otherUserName, currentUserId, currentUserName } = req.body;
    
    // Check if chat already exists
    let chat = await Chat.findOne({
      participants: { $all: [currentUserId, otherUserId] },
    });
    
    if (!chat) {
      // populate avatars for both participants (if available)
      const avatars = [];
      try {
        const u1 = await User.findById(currentUserId).select('profileImage');
        avatars.push(u1 ? u1.profileImage || '' : '');
      } catch (_) {
        avatars.push('');
      }
      try {
        const u2 = await User.findById(otherUserId).select('profileImage');
        avatars.push(u2 ? u2.profileImage || '' : '');
      } catch (_) {
        avatars.push('');
      }

      chat = new Chat({
        participants: [currentUserId, otherUserId],
        participantNames: [currentUserName, otherUserName],
        participantAvatars: avatars,
        lastMessage: 'Start a conversation',
        lastMessageTime: new Date(),
        unreadCount: { [currentUserId]: 0, [otherUserId]: 0 },
      });
      await chat.save();
    }
    
    res.json(chat);
  } catch (error) {
    console.error('Create chat error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get all chat users for starting a new conversation
router.get('/users', protect, async (req, res) => {
  try {
    const { search } = req.query;
    
    // Build filter: exclude self, active status, and residents only
    let filter = {
      _id: { $ne: req.user.id },
      status: 'active',
      role: 'resident' // Only show residents
    };
    
    // Add search filter if provided
    if (search && search.trim()) {
      const searchTerm = search.trim();
      filter.$or = [
        { name: { $regex: searchTerm, $options: 'i' } }, // Case-insensitive search
        { email: { $regex: searchTerm, $options: 'i' } }
      ];
    }
    
    const users = await User.find(filter).select('-password');

    const mappedUsers = users.map(user => ({
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      phone: user.phone,
      apartment: user.apartment,
      role: user.role,
      status: user.status,
      profileImage: user.profileImage,
    }));

    res.json(mappedUsers);
  } catch (error) {
    console.error('Get chat users error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Update a message (only sender can update)
router.put('/messages/:messageId', protect, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { text } = req.body;
    const message = await Message.findById(messageId);
    if (!message) return res.status(404).json({ message: 'Message not found' });
    if (message.senderId !== req.user.id) return res.status(403).json({ message: 'Not authorized' });

    message.text = (text || '').toString().trim();
    await message.save();

    // Emit update via socket.io
    const io = req.app.get('io');
    if (io) io.emit('message-updated', message.toJSON());

    res.json(message);
  } catch (error) {
    console.error('Update message error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Delete a message (hard delete) - sender can delete
router.delete('/messages/:messageId', protect, async (req, res) => {
  try {
    const { messageId } = req.params;
    const message = await Message.findById(messageId);
    if (!message) return res.status(404).json({ message: 'Message not found' });
    if (message.senderId !== req.user.id) return res.status(403).json({ message: 'Not authorized' });

    await Message.findByIdAndDelete(messageId);

    const io = req.app.get('io');
    if (io) io.emit('message-deleted', { messageId });

    res.json({ message: 'Message deleted' });
  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;