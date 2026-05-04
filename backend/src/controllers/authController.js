const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const generateOTP = require('../utils/otpGenerator');
const { sendOTPEmail } = require('../utils/emailService');

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN
  });
};

// ========== REGISTER ==========
const register = async (req, res) => {
  try {
    const { name, email, password, phone, apartment, role, specialization } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }

    // Generate OTP
    const otp = generateOTP();
    const salt = await bcrypt.genSalt(10);
    const hashedOTP = await bcrypt.hash(otp, salt);
    const otpExpire = new Date(Date.now() + 15 * 60 * 1000);

    // Create user (unverified)
    const user = await User.create({
      name,
      email,
      password,
      phone,
      apartment,
      role: role || 'resident',
      specialization: specialization || null,
      status: role === 'admin' ? 'active' : 'pending',
      isEmailVerified: false,
      otp: hashedOTP,
      otpExpire: otpExpire
    });

    // Send OTP email
    const emailSent = await sendOTPEmail({
      email: user.email,
      name: user.name,
      otp: otp
    });

    if (!emailSent) {
      // Rollback user creation if email fails
      await User.findByIdAndDelete(user._id);
      return res.status(500).json({ message: 'Failed to send verification email. Please try again.' });
    }

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Registration successful. Please check your email for verification OTP.',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        apartment: user.apartment,
        role: user.role,
        specialization: user.specialization,
        status: user.status,
        profileImage: user.profileImage,
        isEmailVerified: user.isEmailVerified
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== VERIFY OTP ==========
const verifyOTP = async (req, res) => {
  try {
    const { userId, otp } = req.body;

    if (!userId || !otp) {
      return res.status(400).json({ message: 'User ID and OTP are required' });
    }

    const user = await User.findById(userId).select('+otp +otpExpire');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }

    // Check if OTP is expired
    if (user.otpExpire < Date.now()) {
      return res.status(400).json({ 
        message: 'OTP has expired. Please request a new one.',
        expired: true
      });
    }

    // Verify OTP
    const isValid = await bcrypt.compare(otp, user.otp);
    if (!isValid) {
      return res.status(400).json({ message: 'Invalid OTP' });
    }

    // Mark as verified
    user.isEmailVerified = true;
    user.otp = null;
    user.otpExpire = null;
    user.status = 'active';
    await user.save();

    // Generate new token
    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Email verified successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        apartment: user.apartment,
        role: user.role,
        status: user.status,
        isEmailVerified: user.isEmailVerified
      }
    });
  } catch (error) {
    console.error('OTP verification error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== RESEND OTP ==========
const resendOTP = async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: 'User ID is required' });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }

    // Generate new OTP
    const newOtp = generateOTP();
    const salt = await bcrypt.genSalt(10);
    const hashedOTP = await bcrypt.hash(newOtp, salt);
    
    user.otp = hashedOTP;
    user.otpExpire = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    // Send new OTP
    const emailSent = await sendOTPEmail({
      email: user.email,
      name: user.name,
      otp: newOtp,
    });

    if (!emailSent) {
      return res.status(500).json({ message: 'Failed to send verification email' });
    }

    res.json({
      success: true,
      message: 'New verification code sent to your email',
    });
  } catch (error) {
    console.error('Resend OTP error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== LOGIN ==========
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }

    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check if email is verified
    if (!user.isEmailVerified) {
      return res.status(401).json({ 
        message: 'Please verify your email address before logging in.',
        requiresVerification: true,
        userId: user._id
      });
    }

    if (user.status !== 'active') {
      return res.status(401).json({ message: 'Account is pending approval. Please wait for admin approval.' });
    }

    const token = generateToken(user._id);

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        apartment: user.apartment,
        role: user.role,
        status: user.status,
      profileImage: user.profileImage,
      isEmailVerified: user.isEmailVerified
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== GET CURRENT USER ==========
const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      apartment: user.apartment,
      role: user.role,
      status: user.status,
      profileImage: user.profileImage,
      isEmailVerified: user.isEmailVerified
    });
  } catch (error) {
    console.error('Get me error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== UPDATE PROFILE ==========
const updateProfile = async (req, res) => {
  try {
    const { name, phone, apartment } = req.body;

    const user = await User.findById(req.user.id);

    if (name) user.name = name;
    if (phone) user.phone = phone;
    if (apartment) user.apartment = apartment;
    
    // Handle profile image upload
    if (req.file) {
      user.profileImage = `/uploads/${req.file.filename}`;
    } else if (req.body && (req.body.removeProfileImage === 'true' || req.body.removeProfileImage === true)) {
      // allow frontend to request removing current profile image
      user.profileImage = null;
    }
    
    user.updatedAt = Date.now();

    await user.save();

    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      apartment: user.apartment,
      role: user.role,
      profileImage: user.profileImage,
      isEmailVerified: user.isEmailVerified
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== CHANGE PASSWORD ==========
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.user.id).select('+password');

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    user.password = newPassword;
    await user.save();

    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== GET ALL USERS (Admin) ==========
const getAllUsers = async (req, res) => {
  try {
    const users = await User.find({}).select('-password -otp');
    res.json(users);
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== UPDATE USER ROLE (Admin) ==========
const updateUserRole = async (req, res) => {
  try {
    const { role } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role, updatedAt: Date.now() },
      { new: true }
    ).select('-password -otp');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Include profileImage in response
    const userObj = user.toObject();
    userObj.profileImage = user.profileImage;
    res.json(userObj);
  } catch (error) {
    console.error('Update user role error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== UPDATE USER STATUS (Admin) ==========
const updateUserStatus = async (req, res) => {
  try {
    const { status } = req.body;
    
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.status = status;
    user.updatedAt = Date.now();
    await user.save();

    const updatedUser = await User.findById(user._id).select('-password -otp');
    res.json(updatedUser);
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({ message: error.message });
  }
};

// Exports will be declared after all controller functions are defined

// ========== DELETE USER (Admin) ==========
const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Optionally remove profile image file from disk (best-effort)
    try {
      if (user.profileImage && user.profileImage.startsWith('/uploads/')) {
        const fs = require('fs');
        const path = require('path');
        const filePath = path.join(process.cwd(), user.profileImage);
        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
      }
    } catch (e) {
      console.warn('Failed to remove profile image file:', e.message || e);
    }

    await User.findByIdAndDelete(req.params.id);
    res.json({ message: 'User deleted' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: error.message });
  }
};

// exports will be attached after all functions are defined

// ========== CREATE USER (Admin) ==========
const createUserAdmin = async (req, res) => {
  try {
    const { name, email, password, phone, apartment, role, specialization, status } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }

    // If no password provided, generate a temporary one
    const tempPassword = password || Math.random().toString(36).slice(-8);

    // Create user as verified (admin created)
    const user = await User.create({
      name,
      email,
      password: tempPassword,
      phone,
      apartment,
      role: role || 'resident',
      specialization: specialization || null,
      status: status || (role === 'admin' ? 'active' : 'active'),
      isEmailVerified: true
    });

    res.status(201).json({
      success: true,
      message: 'User created by admin',
      tempPassword,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        apartment: user.apartment,
        role: user.role,
        specialization: user.specialization,
        status: user.status,
        profileImage: user.profileImage
      }
    });
  } catch (error) {
    console.error('Admin create user error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  register,
  login,
  getMe,
  updateProfile,
  changePassword,
  getAllUsers,
  updateUserRole,
  updateUserStatus,
  createUserAdmin,
  deleteUser,
  verifyOTP,
  resendOTP
};