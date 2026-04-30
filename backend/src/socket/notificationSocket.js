/**
 * Socket.io logic for notifications
 * This module handles all Socket.io emit operations for the notification system
 */

// Store io instance globally so it can be accessed from other parts of the app
let ioInstance = null;

// Initialize Socket.io instance
const initNotificationSocket = (io) => {
  ioInstance = io;
  console.log('✅ Notification Socket initialized');

  io.on('connection', (socket) => {
    console.log(`📱 Notification socket connected: ${socket.id}`);

    // Listen for user joining with their userId
    socket.on('join-notification-room', (userId) => {
      socket.join(`user-${userId}`);
      console.log(`✅ User ${userId} joined notification room`);
    });

    // Listen for users leaving
    socket.on('disconnect', () => {
      console.log(`📱 Notification socket disconnected: ${socket.id}`);
    });
  });
};

// Emit notification to a specific user
const emitToUser = (userId, notification) => {
  if (ioInstance) {
    ioInstance.to(`user-${userId}`).emit('notification-received', notification);
    console.log(`📤 Notification emitted to user ${userId}`);
  }
};

// Emit notification to all residents (staff_added, event_approved)
const emitToAllResidents = (residents, notification) => {
  if (ioInstance) {
    residents.forEach(resident => {
      ioInstance.to(`user-${resident._id}`).emit('notification-received', notification);
    });
    console.log(`📤 Notification emitted to ${residents.length} residents`);
  }
};

// Get io instance
const getIoInstance = () => ioInstance;

module.exports = {
  initNotificationSocket,
  emitToUser,
  emitToAllResidents,
  getIoInstance
};
