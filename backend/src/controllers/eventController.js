const Event = require('../models/Event');
const { v4: uuidv4 } = require('uuid');
const { saveAndEmitToAllResidents } = require('../helpers/notificationHelper');

// Store io instance for real-time notifications
let io;
const setIo = (ioInstance) => { io = ioInstance; };

// @desc    Create a new event (Resident)
// @route   POST /api/events
const createEvent = async (req, res) => {
  try {
    const { title, description, date, time, location, category, imageBase64, capacity } = req.body;
    
    const event = new Event({
      id: uuidv4(),
      title,
      description,
      date: new Date(date),
      time,
      location,
      category: category || 'social',
      imageBase64: imageBase64 || '',
      capacity: capacity || 0,
      status: 'pending',
      createdBy: req.user.id,
      createdByName: req.user.name,
    });
    
    await event.save();
    
    res.status(201).json({
      success: true,
      message: 'Event created successfully. Waiting for admin approval.',
      event
    });
  } catch (error) {
    console.error('Create event error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all approved events (Public)
// @route   GET /api/events
const getAllEvents = async (req, res) => {
  try {
    // Return all approved, active events. Previously this endpoint filtered
    // out events whose `date` was earlier than "now" which caused some
    // approved events to be missing from the resident UI (timezones and
    // date-only values could make the comparison exclude valid events).
    // Removing the date filter ensures all approved events are visible.
    const events = await Event.find({ 
      status: 'approved', 
      isActive: true,
    }).sort({ date: 1 });
    
    res.json(events);
  } catch (error) {
    console.error('Get events error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get event by ID
// @route   GET /api/events/:id
const getEventById = async (req, res) => {
  try {
    const event = await Event.findOne({ id: req.params.id });
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    res.json(event);
  } catch (error) {
    console.error('Get event error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get user's own events
// @route   GET /api/events/my-events
const getMyEvents = async (req, res) => {
  try {
    const events = await Event.find({ createdBy: req.user.id }).sort({ createdAt: -1 });
    res.json(events);
  } catch (error) {
    console.error('Get my events error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update event (owner only)
// @route   PUT /api/events/:id
const updateEvent = async (req, res) => {
  try {
    const event = await Event.findOne({ id: req.params.id });
    
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    // Only creator or admin can update
    if (event.createdBy !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    // If event is already approved, can't edit
    if (event.status === 'approved') {
      return res.status(400).json({ message: 'Cannot edit approved event' });
    }
    
    const allowedUpdates = ['title', 'description', 'date', 'time', 'location', 'category', 'imageBase64', 'capacity'];
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        event[field] = req.body[field];
      }
    });
    
    await event.save();
    res.json(event);
  } catch (error) {
    console.error('Update event error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Cancel event (owner only)
// @route   DELETE /api/events/:id
const cancelEvent = async (req, res) => {
  try {
    const event = await Event.findOne({ id: req.params.id });
    
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    // Only creator or admin can cancel
    if (event.createdBy !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    event.isActive = false;
    event.status = 'cancelled';
    await event.save();
    
    res.json({ message: 'Event cancelled successfully' });
  } catch (error) {
    console.error('Cancel event error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== ADMIN ONLY FUNCTIONS ==========

// @desc    Get all pending events (Admin only)
// @route   GET /api/events/admin/pending
const getPendingEvents = async (req, res) => {
  try {
    const events = await Event.find({ status: 'pending', isActive: true }).sort({ createdAt: -1 });
    res.json(events);
  } catch (error) {
    console.error('Get pending events error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all events for admin (Admin only)
// @route   GET /api/events/admin/all
const getAllEventsAdmin = async (req, res) => {
  try {
    const events = await Event.find({ isActive: true }).sort({ createdAt: -1 });
    res.json(events);
  } catch (error) {
    console.error('Get all events admin error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Approve event (Admin only)
// @route   PUT /api/events/admin/:id/approve
const approveEvent = async (req, res) => {
  try {
    const event = await Event.findOne({ id: req.params.id });
    
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    event.status = 'approved';
    event.approvedBy = req.user.id;
    event.approvedAt = new Date();
    await event.save();
    
    await saveAndEmitToAllResidents(io, {
      type: 'event_approved',
      title: 'Event Approved',
      body: `${event.title} has been approved and is now available!`,
      metadata: {
        eventTitle: event.title,
        eventDate: event.date,
        eventLocation: event.location
      }
    });
    
    res.json({ message: 'Event approved successfully', event });
  } catch (error) {
    console.error('Approve event error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Reject event (Admin only)
// @route   PUT /api/events/admin/:id/reject
const rejectEvent = async (req, res) => {
  try {
    const { reason } = req.body;
    const event = await Event.findOne({ id: req.params.id });
    
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    event.status = 'rejected';
    event.rejectionReason = reason || 'No reason provided';
    await event.save();
    
    res.json({ message: 'Event rejected successfully', event });
  } catch (error) {
    console.error('Reject event error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete event (Admin only)
// @route   DELETE /api/events/admin/:id
const deleteEvent = async (req, res) => {
  try {
    const event = await Event.findOne({ id: req.params.id });
    
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    event.isActive = false;
    await event.save();
    
    res.json({ message: 'Event deleted successfully' });
  } catch (error) {
    console.error('Delete event error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createEvent,
  getAllEvents,
  getEventById,
  getMyEvents,
  updateEvent,
  cancelEvent,
  getPendingEvents,
  getAllEventsAdmin,
  approveEvent,
  rejectEvent,
  deleteEvent,
  setIo,
};