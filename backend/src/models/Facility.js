const mongoose = require('mongoose');

const facilitySchema = new mongoose.Schema({
  id: { 
    type: String, 
    required: [true, 'Facility ID is required'],
    unique: true,
    trim: true
  },
  name: { 
    type: String, 
    required: [true, 'Facility name is required'],
    trim: true,
    minlength: [3, 'Name must be at least 3 characters']
  },
  description: { 
    type: String, 
    required: [true, 'Description is required'],
    trim: true,
    minlength: [10, 'Description must be at least 10 characters']
  },
  capacity: { 
    type: Number, 
    required: [true, 'Capacity is required'],
    min: [1, 'Capacity must be at least 1']
  },
  hours: { 
    type: String, 
    required: [true, 'Operating hours are required'],
    trim: true
  },
  imagesBase64: {
    type: [String],
    validate: {
      validator: function(array) {
        return array && array.length > 0;
      },
      message: 'At least one image is required'
    }
  },
  features: [String],
  rules: [String],
  pricePerHour: { 
    type: Number, 
    required: [true, 'Price per hour is required'],
    min: [0, 'Price cannot be negative']
  },
  isActive: { 
    type: Boolean, 
    default: true 
  },
  createdBy: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    required: [true, 'Created by user ID is required']
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Index for faster queries
facilitySchema.index({ createdBy: 1, isActive: 1 });
facilitySchema.index({ createdAt: -1 });

module.exports = mongoose.model('Facility', facilitySchema);