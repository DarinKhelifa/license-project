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
    
    res.json(chats);
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
      chat = new Chat({
        participants: [currentUserId, otherUserId],
        participantNames: [currentUserName, otherUserName],
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
    const users = await User.find({
      _id: { $ne: req.user.id },
      status: 'active',
    }).select('-password');

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

module.exports = router;