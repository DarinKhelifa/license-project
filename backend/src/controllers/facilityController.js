const Facility = require('../models/Facility');

// @desc    Create a new facility
// @route   POST /api/facilities
const createFacility = async (req, res) => {
  try {
    // Validate required fields
    const { id, name, description, capacity, hours, imagesBase64, pricePerHour, features, rules } = req.body;
    
    if (!id || !name || !description || capacity === undefined || !hours || !imagesBase64 || pricePerHour === undefined) {
      return res.status(400).json({ 
        message: 'Missing required fields',
        required: ['id', 'name', 'description', 'capacity', 'hours', 'imagesBase64', 'pricePerHour']
      });
    }

    // Validate data types
    if (typeof capacity !== 'number' || capacity < 1) {
      return res.status(400).json({ message: 'Capacity must be a positive number' });
    }

    if (typeof pricePerHour !== 'number' || pricePerHour < 0) {
      return res.status(400).json({ message: 'Price per hour must be a non-negative number' });
    }

    if (!Array.isArray(imagesBase64) || imagesBase64.length === 0) {
      return res.status(400).json({ message: 'At least one image is required' });
    }

    // Check image size (warn if total is getting large)
    const totalImageSize = imagesBase64.reduce((sum, img) => sum + (img ? img.length : 0), 0);
    console.log(`Total image size: ${(totalImageSize / 1024 / 1024).toFixed(2)} MB`);
    if (totalImageSize > 10000000) { // 10MB limit for base64
      return res.status(400).json({ message: 'Images are too large. Total size exceeds 10MB' });
    }

    const facility = new Facility({
      id: id.trim(),
      name: name.trim(),
      description: description.trim(),
      capacity: parseInt(capacity),
      hours: hours.trim(),
      imagesBase64,
      features: features || [],
      rules: rules || [],
      pricePerHour: parseFloat(pricePerHour),
      createdBy: req.user.id,
      createdAt: new Date(),
      updatedAt: new Date()
    });

    const savedFacility = await facility.save();
    console.log('✅ Facility created successfully:', savedFacility.id);
    res.status(201).json(savedFacility);
  } catch (error) {
    console.error('❌ Create facility error:', error.message);
    
    // Handle MongoDB validation errors
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({ 
        message: 'Validation error',
        errors: messages
      });
    }

    // Handle duplicate key error
    if (error.code === 11000) {
      return res.status(400).json({ 
        message: 'A facility with this ID already exists' 
      });
    }

    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all facilities
// @route   GET /api/facilities
const getAllFacilities = async (req, res) => {
  try {
    const facilities = await Facility.find({ isActive: true })
      .populate('createdBy', 'name email')
      .sort({ createdAt: -1 });
    res.json(facilities);
  } catch (error) {
    console.error('❌ Get facilities error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get facility by ID
// @route   GET /api/facilities/:id
const getFacilityById = async (req, res) => {
  try {
    // Search by custom 'id' field instead of MongoDB '_id'
    const facility = await Facility.findOne({ id: req.params.id })
      .populate('createdBy', 'name email');
    if (!facility) {
      console.log('❌ Facility not found with id:', req.params.id);
      return res.status(404).json({ message: 'Facility not found' });
    }
    console.log('✅ Facility found:', facility.id);
    res.json(facility);
  } catch (error) {
    console.error('❌ Get facility error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update facility
// @route   PUT /api/facilities/:id
const updateFacility = async (req, res) => {
  try {
    const { id: facilityId } = req.params;
    const updateData = { ...req.body, updatedAt: new Date() };

    // Validate numeric fields if provided
    if (updateData.capacity !== undefined) {
      const cap = parseInt(updateData.capacity);
      if (isNaN(cap) || cap < 1) {
        return res.status(400).json({ message: 'Capacity must be a positive number' });
      }
      updateData.capacity = cap;
    }

    if (updateData.pricePerHour !== undefined) {
      const price = parseFloat(updateData.pricePerHour);
      if (isNaN(price) || price < 0) {
        return res.status(400).json({ message: 'Price per hour must be a non-negative number' });
      }
      updateData.pricePerHour = price;
    }

    // Check image size if provided
    if (updateData.imagesBase64 && Array.isArray(updateData.imagesBase64)) {
      const totalImageSize = updateData.imagesBase64.reduce((sum, img) => sum + (img ? img.length : 0), 0);
      if (totalImageSize > 10000000) {
        return res.status(400).json({ message: 'Images are too large. Total size exceeds 10MB' });
      }
    }

    // Find and update by custom 'id' field
    const facility = await Facility.findOneAndUpdate(
      { id: facilityId },
      updateData,
      { new: true, runValidators: true }
    );

    if (!facility) {
      return res.status(404).json({ message: 'Facility not found' });
    }

    console.log('✅ Facility updated successfully:', facility.id);
    res.json(facility);
  } catch (error) {
    console.error('❌ Update facility error:', error.message);
    
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

// @desc    Delete facility (soft delete)
// @route   DELETE /api/facilities/:id
const deleteFacility = async (req, res) => {
  try {
    // Find and update by custom 'id' field
    const facility = await Facility.findOneAndUpdate(
      { id: req.params.id },
      { isActive: false, updatedAt: new Date() },
      { new: true }
    );
    if (!facility) {
      return res.status(404).json({ message: 'Facility not found' });
    }
    console.log('✅ Facility deleted successfully:', facility.id);
    res.json({ message: 'Facility deleted successfully', facility });
  } catch (error) {
    console.error('❌ Delete facility error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createFacility,
  getAllFacilities,
  getFacilityById,
  updateFacility,
  deleteFacility,
};