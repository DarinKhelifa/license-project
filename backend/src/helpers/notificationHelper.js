const Notification = require('../models/Notification');
const User = require('../models/User');
const { emitToUser, emitToAllResidents } = require('../socket/notificationSocket');

/**
 * Save notification and emit it via Socket.io
 * @param {Object} io - Socket.io instance
 * @param {Object} options - Notification options
 * @returns {Promise<Object>} - Created notification
 */
const saveAndEmitNotification = async (io, options) => {
  try {
    const { type, userId, title, body, metadata = {} } = options;

    // Create and save notification to database
    const notification = new Notification({
      userId,
      type,
      title,
      body,
      metadata
    });

    const savedNotification = await notification.save();
    console.log(`✅ Notification saved: ${type} for user ${userId}`);

    // Emit via Socket.io to specific user
    emitToUser(userId, {
      _id: savedNotification._id,
      type: savedNotification.type,
      title: savedNotification.title,
      body: savedNotification.body,
      metadata: savedNotification.metadata,
      createdAt: savedNotification.createdAt
    });

    return savedNotification;
  } catch (error) {
    console.error('❌ Error in saveAndEmitNotification:', error);
    throw error;
  }
};

/**
 * Save and emit notification to all residents
 * @param {Object} io - Socket.io instance
 * @param {Object} options - Notification options
 * @returns {Promise<Array>} - Array of created notifications
 */
const saveAndEmitToAllResidents = async (io, options) => {
  try {
    const { type, title, body, metadata = {} } = options;
    const allResidents = await User.find({ role: 'resident' });
    const savedNotifications = [];

    for (const resident of allResidents) {
      const notification = new Notification({
        userId: resident._id,
        type,
        title,
        body,
        metadata
      });

      const saved = await notification.save();
      savedNotifications.push(saved);

      // Emit to each resident
      emitToAllResidents([resident], {
        _id: saved._id,
        type: saved.type,
        title: saved.title,
        body: saved.body,
        metadata: saved.metadata,
        createdAt: saved.createdAt
      });
    }

    console.log(`✅ Notifications saved and emitted to ${allResidents.length} residents`);
    return savedNotifications;
  } catch (error) {
    console.error('❌ Error in saveAndEmitToAllResidents:', error);
    throw error;
  }
};

module.exports = {
  saveAndEmitNotification,
  saveAndEmitToAllResidents
};
