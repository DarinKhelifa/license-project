const User = require('../models/User');

// GET /api/settings/me
const getSettings = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password -otp');
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      profileImage: user.profileImage,
      settings: user.settings || {}
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({ message: error.message });
  }
};

// PUT /api/settings/appearance
const updateAppearance = async (req, res) => {
  try {
    const { theme, reducedMotion } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.settings = user.settings || {};
    user.settings.appearance = user.settings.appearance || {};
    if (theme) user.settings.appearance.theme = theme;
    if (typeof reducedMotion === 'boolean') user.settings.appearance.reducedMotion = reducedMotion;

    await user.save();
    res.json({ settings: user.settings });
  } catch (error) {
    console.error('Update appearance error:', error);
    res.status(500).json({ message: error.message });
  }
};

// PUT /api/settings/notifications
const updateNotifications = async (req, res) => {
  try {
    const { inApp, email, sms } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.settings = user.settings || {};
    user.settings.notifications = user.settings.notifications || {};
    if (typeof inApp === 'boolean') user.settings.notifications.inApp = inApp;
    if (typeof email === 'boolean') user.settings.notifications.email = email;
    if (typeof sms === 'boolean') user.settings.notifications.sms = sms;

    await user.save();
    res.json({ settings: user.settings });
  } catch (error) {
    console.error('Update notifications error:', error);
    res.status(500).json({ message: error.message });
  }
};

// PUT /api/settings/security
const updateSecurity = async (req, res) => {
  try {
    const { twoFactorEnabled } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.settings = user.settings || {};
    user.settings.security = user.settings.security || {};
    if (typeof twoFactorEnabled === 'boolean') user.settings.security.twoFactorEnabled = twoFactorEnabled;

    await user.save();
    res.json({ settings: user.settings });
  } catch (error) {
    console.error('Update security error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getSettings,
  updateAppearance,
  updateNotifications,
  updateSecurity
};
