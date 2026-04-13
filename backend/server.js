const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const { v4: uuidv4 } = require('uuid');
const QRCode = require('qrcode');
const http = require('http');
const socketIo = require('socket.io');

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./src/routes/authRoutes');
const facilityRoutes = require('./src/routes/facilityRoutes');
const bookingRoutes = require('./src/routes/bookingRoutes');
const chatRoutes = require('./src/routes/chatRoutes');
const eventRoutes = require('./src/routes/eventRoutes');
const reportRoutes = require('./src/routes/reportRoutes');
const guestRoutes = require('./src/routes/guestRoutes');
const employeeRoutes = require('./src/routes/employeeRoutes');


const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: ['http://localhost:3000', 'http://localhost:8080','http://localhost:58010/', 'http://localhost:5000', 'http://127.0.0.1:5000', 'http://127.0.0.1:8080'],
    methods: ['GET', 'POST'],
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
  transports: ['websocket', 'polling'], // Add this
});

// Middleware 
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/uploads', express.static('uploads'));

// Database connection 
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ MongoDB connected successfully'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/facilities', facilityRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/guests', guestRoutes);
app.use('/api/employees', employeeRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'ORELAX API is running' });
});

// Socket.io Chat Logic
const Chat = require('./src/models/Chat');
const Message = require('./src/models/Message');
const Report = require('./src/models/Report');
const reportController = require('./src/controllers/reportController');
reportController.setIo(io);

// Store online users
const onlineUsers = new Map();

io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  // User joins with their userId and role
  socket.on('user-connected', (data) => {
    const { userId, role } = data;
    onlineUsers.set(userId, { socketId: socket.id, role });
    console.log(`User ${userId} (${role}) connected. Online users: ${onlineUsers.size}`);
    
    // Join role-based room for alerts
    if (role) {
      socket.join(`role-${role}`);
      console.log(`User ${userId} joined role-${role} room`);
    }
    
    // Broadcast online status to all users
    io.emit('users-online', Array.from(onlineUsers.keys()).map(id => ({ userId: id })));
  });

  // Send a message
  socket.on('send-message', async (data) => {
    try {
      const { chatId, senderId, senderName, text, type = 'text' } = data;
      console.log(`📤 receive send-message for chat=${chatId} sender=${senderId} text=${text}`);
      
      const message = new Message({
        chatId,
        senderId,
        senderName,
        text,
        type,
        status: 'sent',
        readBy: [senderId],
      });
      const savedMessage = await message.save();
      console.log(`💾 message saved ${savedMessage._id}`);
      
      const chat = await Chat.findById(chatId);
      if (!chat) {
        console.warn(`⚠️ Chat not found for chatId=${chatId}`);
        socket.emit('message-error', { error: 'Chat not found' });
        return;
      }

      const recipientId = chat.participants.find(p => p !== senderId);
      console.log(`👥 recipientId=${recipientId}`);
      const updateOps = {
        $set: {
          lastMessage: text,
          lastMessageTime: new Date(),
          lastMessageSenderId: senderId,
        },
      };

      if (recipientId) {
        updateOps.$inc = { [`unreadCount.${recipientId}`]: 1 };
      }

      await Chat.findByIdAndUpdate(chatId, updateOps);
      console.log(`✅ Chat metadata updated`);

      const recipientData = onlineUsers.get(recipientId);
      const recipientSocketId = recipientData?.socketId;
      console.log(`🔌 recipientSocketId=${recipientSocketId}, onlineUsers size=${onlineUsers.size}`);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit('new-message', savedMessage.toJSON());
        console.log(`📬 message delivered to recipient socket`);
      }

      const messageJSON = savedMessage.toJSON();
      socket.emit('new-message', messageJSON);
      socket.emit('message-sent', messageJSON);
      console.log(`✅ message sent to sender`);
      
    } catch (error) {
      console.error('❌ Send message error:', error);
      socket.emit('message-error', { error: error.message });
    }
  });

  // Mark message as read
  socket.on('mark-read', async (data) => {
    try {
      const { messageId, userId, chatId } = data;
      
      await Message.findByIdAndUpdate(messageId, {
        $addToSet: { readBy: userId },
        status: 'read',
      });
      
      await Chat.findByIdAndUpdate(chatId, {
        $set: { [`unreadCount.${userId}`]: 0 },
      });
      
      const message = await Message.findById(messageId);
      if (message) {
        const senderData = onlineUsers.get(message.senderId);
        const senderSocketId = senderData?.socketId;
        if (senderSocketId) {
          io.to(senderSocketId).emit('message-read', { messageId, userId });
        }
      }
      
    } catch (error) {
      console.error('Mark read error:', error);
    }
  });

  // User typing indicator
  socket.on('typing', (data) => {
    const { chatId, userId, isTyping } = data;
    socket.broadcast.emit('user-typing', { chatId, userId, isTyping });
  });

  // User disconnects
  socket.on('disconnect', () => {
    let disconnectedUserId;
    for (let [userId, data] of onlineUsers.entries()) {
      if (data.socketId === socket.id) {
        disconnectedUserId = userId;
        onlineUsers.delete(userId);
        break;
      }
    }
    if (disconnectedUserId) {
      console.log(`User ${disconnectedUserId} disconnected`);
      io.emit('users-online', Array.from(onlineUsers.keys()).map(id => ({ userId: id })));
    }
  });
}

);
// Add connection error logging
io.engine.on('connection_error', (err) => {
  console.log('Connection error:', err);
});
// Error handling middleware
app.use((err, req, res, next) => {
  console.error('ERROR:', err);
  res.status(500).json({ 
    message: err.message || 'Something went wrong!',
    details: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});