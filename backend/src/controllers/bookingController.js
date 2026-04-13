const Booking = require('../models/Booking');
const Facility = require('../models/Facility');

// @desc    Create a booking
// @route   POST /api/bookings
const createBooking = async (req, res) => {
  try {
    const { id, facilityId, bookingDate, startTime, endTime, duration, userName, userEmail, userPhone } = req.body;

    // Validate required fields (totalPrice removed since all bookings are free)
    if (!id || !facilityId || !bookingDate || !startTime || !endTime || !duration || !userName || !userEmail || !userPhone) {
      return res.status(400).json({
        message: 'Missing required fields',
        required: ['id', 'facilityId', 'bookingDate', 'startTime', 'endTime', 'duration', 'userName', 'userEmail', 'userPhone']
      });
    }

    // Validate facility exists
    const facility = await Facility.findOne({ id: facilityId });
    if (!facility) {
      return res.status(404).json({ message: 'Facility not found' });
    }

    // Check for overlapping bookings
    const bookingDateObj = new Date(bookingDate);
    const dayStart = new Date(bookingDateObj);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(bookingDateObj);
    dayEnd.setHours(23, 59, 59, 999);

    const conflictingBooking = await Booking.findOne({
      facilityId,
      bookingDate: { $gte: dayStart, $lte: dayEnd },
      status: { $in: ['pending', 'confirmed'] },
      $expr: {
        $or: [
          // New booking starts before existing ends
          { $and: [
            { $gte: ['$startTime', startTime] },
            { $lt: ['$startTime', endTime] }
          ]},
          // New booking ends after existing starts
          { $and: [
            { $gt: ['$endTime', startTime] },
            { $lte: ['$endTime', endTime] }
          ]},
          // New booking entirely contains existing
          { $and: [
            { $lte: ['$startTime', startTime] },
            { $gte: ['$endTime', endTime] }
          ]}
        ]
      }
    });

    if (conflictingBooking) {
      return res.status(409).json({ message: 'Time slot already booked for this facility' });
    }

    const booking = new Booking({
      id: id.trim(),
      facilityId,
      userId: req.user.id,
      bookingDate: new Date(bookingDate),
      startTime: startTime.trim(),
      endTime: endTime.trim(),
      duration: parseInt(duration),
      totalPrice: 0, // All bookings are free now
      status: 'pending',
      userName: userName.trim(),
      userEmail: userEmail.trim(),
      userPhone: userPhone.trim(),
      createdAt: new Date(),
      updatedAt: new Date()
    });

    const savedBooking = await booking.save();
    console.log('✅ Booking created successfully:', savedBooking.id);
    res.status(201).json(savedBooking);
  } catch (error) {
    console.error('❌ Create booking error:', error.message);

    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        message: 'Validation error',
        errors: messages
      });
    }

    res.status(500).json({ message: error.message });
  }
};

// @desc    Get user's bookings
// @route   GET /api/bookings/my-bookings
const getUserBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user.id })
      .sort({ bookingDate: -1 });
    res.json(bookings);
  } catch (error) {
    console.error('❌ Get user bookings error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get available time slots for a facility
// @route   GET /api/bookings/availability/:facilityId
const getAvailableSlots = async (req, res) => {
  try {
    const { facilityId } = req.params;
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({ message: 'Date parameter is required' });
    }

    const facility = await Facility.findOne({ id: facilityId });
    if (!facility) {
      return res.status(404).json({ message: 'Facility not found' });
    }

    // Parse date
    const dateObj = new Date(date);
    const dayStart = new Date(dateObj);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(dateObj);
    dayEnd.setHours(23, 59, 59, 999);

    // Get all bookings for this facility on this date
    const bookings = await Booking.find({
      facilityId,
      bookingDate: { $gte: dayStart, $lte: dayEnd },
      status: { $in: ['pending', 'confirmed'] }
    }).sort({ startTime: 1 });

    // Generate all time slots (08:00 to 20:00)
    const allTimeSlots = [
      '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
      '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'
    ];

    // Find booked slots
    const bookedSlots = [];
    bookings.forEach(booking => {
      const startIdx = allTimeSlots.indexOf(booking.startTime);
      const endIdx = allTimeSlots.indexOf(booking.endTime);
      for (let i = startIdx; i < endIdx; i++) {
        bookedSlots.push(allTimeSlots[i]);
      }
    });

    // Find available slots
    const availableSlots = allTimeSlots.filter(slot => !bookedSlots.includes(slot));

    res.json({ availableSlots });
  } catch (error) {
    console.error('❌ Get available slots error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Cancel booking
// @route   PUT /api/bookings/:bookingId/cancel
const cancelBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await Booking.findOneAndUpdate(
      { id: bookingId, userId: req.user.id },
      { status: 'cancelled', updatedAt: new Date() },
      { new: true }
    );

    if (!booking) {
      return res.status(404).json({ message: 'Booking not found or unauthorized' });
    }

    console.log('✅ Booking cancelled successfully:', booking.id);
    res.json({ message: 'Booking cancelled successfully', booking });
  } catch (error) {
    console.error('❌ Cancel booking error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all pending bookings (for facilities manager)
// @route   GET /api/bookings/manager/pending
const getPendingBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ status: 'pending' })
      .sort({ bookingDate: -1 });
    
    console.log('✅ Fetched pending bookings count:', bookings.length);
    res.json(bookings);
  } catch (error) {
    console.error('❌ Get pending bookings error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all bookings with history (for facilities manager)
// @route   GET /api/bookings/manager/history
const getBookingHistory = async (req, res) => {
  try {
    const bookings = await Booking.find({})
      .sort({ bookingDate: -1 });
    
    console.log('✅ Fetched booking history count:', bookings.length);
    res.json(bookings);
  } catch (error) {
    console.error('❌ Get booking history error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Approve a booking (facilities manager)
// @route   PUT /api/bookings/:bookingId/approve
const approveBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await Booking.findOneAndUpdate(
      { id: bookingId },
      { status: 'confirmed', updatedAt: new Date() },
      { new: true }
    );

    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    console.log('✅ Booking approved successfully:', booking.id);
    res.json({ message: 'Booking approved successfully', booking });
  } catch (error) {
    console.error('❌ Approve booking error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Reject a booking (facilities manager)
// @route   PUT /api/bookings/:bookingId/reject
const rejectBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { reason } = req.body;

    const booking = await Booking.findOneAndUpdate(
      { id: bookingId },
      { status: 'cancelled', reason: reason || 'Rejected by facilities manager', updatedAt: new Date() },
      { new: true }
    );

    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    console.log('✅ Booking rejected successfully:', booking.id);
    res.json({ message: 'Booking rejected successfully', booking });
  } catch (error) {
    console.error('❌ Reject booking error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createBooking,
  getUserBookings,
  getAvailableSlots,
  cancelBooking,
  getPendingBookings,
  getBookingHistory,
  approveBooking,
  rejectBooking,
};
