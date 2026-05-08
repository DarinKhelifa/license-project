const ContactMessage = require('../models/ContactMessage');
const { saveAndEmitToRole } = require('../helpers/notificationHelper');

exports.createMessage = async (req, res, next) => {
  try {
    const { name, email, phone, subject, message } = req.body;
    if (!email || !message) return res.status(400).json({ error: 'Email and message are required' });

    const msg = new ContactMessage({ name, email, phone, subject, message });
    const saved = await msg.save();

    // Log and optionally notify admins via socket or email here
    console.log(`New contact message from ${email}: ${message.substring(0, 120)}`);

    // Notify admins about the new contact message
    try {
      await saveAndEmitToRole(null, 'admin', {
        type: 'contact_message',
        title: `Contact form: ${subject || 'New Message'}`,
        body: `${name || email}: ${message.substring(0, 120)}`,
        metadata: { contactId: saved._id }
      });
    } catch (e) {
      console.error('Failed to save/emit contact notification', e);
    }

    return res.status(201).json(saved);
  } catch (err) {
    next(err);
  }
};

exports.listMessages = async (req, res, next) => {
  try {
    const messages = await ContactMessage.find().sort({ createdAt: -1 }).limit(1000);
    res.json(messages);
  } catch (err) {
    next(err);
  }
};

exports.getMessage = async (req, res, next) => {
  try {
    const msg = await ContactMessage.findById(req.params.id);
    if (!msg) return res.status(404).json({ error: 'Not found' });
    res.json(msg);
  } catch (err) {
    next(err);
  }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const updated = await ContactMessage.findByIdAndUpdate(req.params.id, { status }, { new: true });
    res.json(updated);
  } catch (err) {
    next(err);
  }
};
