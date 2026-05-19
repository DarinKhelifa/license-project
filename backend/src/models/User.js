const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true
  },
  apartment: {
    type: String,
    required: [function() { return this.role === 'resident'; }, 'Apartment number is required'],
    trim: true
  },
  residence: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Residence',
    default: null
  },
  building: {
    type: String,
    default: null,
    trim: true
  },
  role: {
    type: String,
    enum: ['resident', 'security', 'maintenance', 'facility_manager', 'admin'],
    default: 'resident'
  },
  specialization: {
    type: String,
    enum: ['cleaning', 'electrician', 'repair', 'plumber', 'other'],
    default: null
  },
  status: {
    type: String,
    enum: ['active', 'pending', 'inactive'],
    default: 'pending'
  },
  profileImage: {
    type: String,
    default: null
  },
  qrToken: {
    type: String,
    default: null
  },
  qrGeneratedAt: {
    type: Date,
    default: null
  },
  // User-specific settings (appearance, notifications, security)
  settings: {
    appearance: {
      theme: { type: String, enum: ['auto', 'light', 'dark'], default: 'auto' },
      reducedMotion: { type: Boolean, default: false }
    },
    notifications: {
      inApp: { type: Boolean, default: true },
      email: { type: Boolean, default: true },
      sms: { type: Boolean, default: false }
    },
    security: {
      twoFactorEnabled: { type: Boolean, default: false }
    }
  },
  // ========== OTP EMAIL VERIFICATION FIELDS ==========
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  otp: {
    type: String,
    default: null,
    select: false
  },
  otpExpire: {
    type: Date,
    default: null
  }
  ,
  // Password reset fields
  resetPasswordToken: {
    type: String,
    default: null,
    select: false
  },
  resetPasswordExpire: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    return next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);