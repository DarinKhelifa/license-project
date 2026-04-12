const mongoose = require('mongoose');

const guestSchema = new mongoose.Schema(
    {
        residentId: {
            type: String,
            required: true,
        },

        guestId: {
            type: String,
            required: true,
            unique: true,
        },

        name: {
            type: String,
            required: true,
            trim: true,
        },

        phone: {
            type: String,
            required: false,  // ✅ Change to false (optional)
            default: '',
            trim: true,
        },

        email: {
            type: String,
            default: '',
            trim: true,
        },

        visitDate: {
            type: String,
            required: true,
        },

        host: {
            type: String,
            required: true,  // ✅ Make sure host is required
            trim: true,
        },

        qrCode: {
            type: String,
            required: true,
        },

        status: {
            type: String,
            enum: ['active', 'used', 'expired', 'cancelled'],
            default: 'active',
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Guest', guestSchema);