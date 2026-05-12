const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const { v4: uuidv4 } = require('uuid');
const QRCode = require('qrcode');
const http = require('http');
const socketIo = require('socket.io');
const dns = require('dns');


// Force public DNS servers for MongoDB SRV lookups (fixes corporate DNS issues)
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./src/routes/authRoutes');
const facilityRoutes = require('./src/routes/facilityRoutes');
const bookingRoutes = require('./src/routes/bookingRoutes');
const chatRoutes = require('./src/routes/chatRoutes');
const eventRoutes = require('./src/routes/eventRoutes');
const reportRoutes = require('./src/routes/reportRoutes');
const securityNoteRoutes = require('./src/routes/securityNoteRoutes');
const guestRoutes = require('./src/routes/guestRoutes');
const employeeRoutes = require('./src/routes/employeeRoutes');
const socialRoutes = require('./src/routes/socialRoutes');
const energyRoutes = require('./src/routes/energyRoutes');
const environmentRoutes = require('./src/routes/environmentRoutes');
const residenceRoutes = require('./src/routes/residenceRoutes');
const { initMQTT } = require('./src/controllers/energyController');
const qrRoutes = require('./src/routes/qrRoutes');
const initSurveillance = require('./src/routes/surveillanceRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes');
const settingsRoutes = require('./src/routes/settingsRoutes');
const contactRoutes = require('./src/routes/contactRoutes');
const parkingRoutes = require('./src/routes/parkingRoutes');
const iotRoutes = require('./src/routes/iotRoutes');

const app = express();
const server = http.createServer(app);

// --- SURVEILLANCE DISABLED FOR NOW ---
// initSurveillance(server); 
// ----------------------------------------

const io = socketIo(server, {
  cors: {
  origin: [
  'http://localhost:3000',
  'http://localhost:8080',
  'http://localhost:58010/',
  'http://localhost:5000',
  'http://127.0.0.1:5000',
  'http://127.0.0.1:8080',
  'http://10.40.104.21:5000',
  '*'
],
    methods: ['GET', 'POST'],
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
  transports: ['websocket', 'polling'], // Add this
});
initMQTT(io);

// Middleware 
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/uploads', express.static('uploads'));

// Database connection 
mongoose.connect(process.env.MONGODB_URI, {
  maxPoolSize: 10,
  minPoolSize: 5,
  serverSelectionTimeoutMS: 30000,
  socketTimeoutMS: 45000,
  family: 4,
  retryWrites: true,
  writeConcern: { w: 1 },
  maxIdleTimeMS: 30000,
})
  .then(() => console.log('✅ MongoDB connected successfully'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/facilities', facilityRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/security-notes', securityNoteRoutes);
app.use('/api/guests', guestRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/social', socialRoutes);
app.use('/api/energy', energyRoutes);
app.use('/api/environment', environmentRoutes);
app.use('/api/residences', residenceRoutes);
app.use('/api/qr', qrRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/parking', parkingRoutes);
app.use('/api/iot', iotRoutes);
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
const { initNotificationSocket } = require('./src/socket/notificationSocket');
initNotificationSocket(io);
const User = require('./src/models/User');
const eventController = require('./src/controllers/eventController');
const employeeController = require('./src/controllers/employeeController');
const { saveAndEmitNotification } = require('./src/helpers/notificationHelper');
eventController.setIo(io);
employeeController.setIo(io);

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
      const { chatId, senderId, senderName, text = '', type = 'text', mediaUrl } = data;
      console.log(`📤 receive send-message for chat=${chatId} sender=${senderId} type=${type} text=${text}`);

      const chat = await Chat.findById(chatId);
      if (!chat) {
        console.warn(`⚠️ Chat not found for chatId=${chatId}`);
        socket.emit('message-error', { error: 'Chat not found' });
        return;
      }

      if (!chat.participants.includes(senderId)) {
        socket.emit('message-error', { error: 'Not authorized for this chat' });
        return;
      }

      const recipientId = chat.participants.find((p) => p !== senderId);
      const blockedUsers = Array.isArray(chat.blockedUsers) ? chat.blockedUsers : [];
      const isBlockedConversation = recipientId
        ? blockedUsers.includes(recipientId) || blockedUsers.includes(senderId)
        : false;

      if (isBlockedConversation) {
        socket.emit('message-error', { error: 'You cannot send messages in this chat because a user is blocked.' });
        return;
      }

      const normalizedText = (typeof text === 'string') ? text.trim() : '';
      const effectiveText = normalizedText || (type === 'image' ? '📷 Photo' : type === 'file' ? '📎 File' : type === 'audio' ? '🎤 Voice message' : '');
      
      const message = new Message({
        chatId,
        senderId,
        senderName,
        text: effectiveText,
        type,
        mediaUrl,
        status: 'sent',
        readBy: [senderId],
      });
      const savedMessage = await message.save();
      console.log(`💾 message saved ${savedMessage._id}`);

      console.log(`👥 recipientId=${recipientId}`);
      const updateOps = {
        $set: {
          lastMessage: effectiveText,
          lastMessageTime: new Date(),
          lastMessageSenderId: senderId,
        },
      };

      if (recipientId) {
        updateOps.$inc = { [`unreadCount.${recipientId}`]: 1 };
      }

      await Chat.findByIdAndUpdate(chatId, updateOps);
      console.log(`✅ Chat metadata updated`);
      // Send message received notification to recipient
      if (recipientId) {
        await saveAndEmitNotification(io, {
          type: 'message_received',
          userId: recipientId,
          title: 'New Message',
          body: `${senderName}: ${effectiveText.substring(0, 50)}${effectiveText.length > 50 ? '...' : ''}`,
          metadata: {
            senderName: senderName,
            senderPreview: effectiveText,
            messageId: savedMessage._id
          }
        });
      }


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

// Graceful handling for common server listen errors (e.g. EADDRINUSE)
server.on('error', (err) => {
  if (err && err.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use (EADDRINUSE).`);
    console.error('Suggestions:');
    console.error(` - Change the PORT in your .env or start command (e.g. PORT=${parseInt(PORT,10)+1})`);
    console.error(' - On Windows: run `netstat -ano | findstr :' + PORT + '` then `taskkill /PID <pid> /F`');
    console.error(' - Or use `npx kill-port ' + PORT + '` to free the port');
    process.exit(1);
  }
  console.error('Server error:', err);
  process.exit(1);
});

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
