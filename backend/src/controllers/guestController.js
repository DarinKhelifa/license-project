const Guest = require('../models/Guest');
const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');

const generateGuestQR = async (req, res) => {
    console.log("📩 Incoming QR request for:", req.body.name);

    try {
        const { name, phone, email, visitDate, host, residentId } = req.body;

        // Validate required fields (phone is optional)
        if (!name || !visitDate || !host || !residentId) {
            console.log("❌ Validation failed: Missing required fields");
            return res.status(400).json({
                success: false,
                error: 'Missing required fields: name, visitDate, host, and residentId are required',
            });
        }

        const guestId = uuidv4();
        
        // Create payload for QR code
        const payload = JSON.stringify({
            id: guestId,
            name: name.trim(),
            host: host.trim(),
            visitDate,
        });

        const qrBase64 = await QRCode.toDataURL(payload);

        const guest = new Guest({
            residentId,
            guestId,
            name: name.trim(),
            phone: phone?.trim() || '',  // Optional - default empty string
            email: email?.trim() || '',
            visitDate,
            host: host.trim(),
            qrCode: qrBase64,
            status: 'active',
        });

        await guest.save();
        console.log("✅ QR Successfully generated and saved to DB");

        return res.status(201).json({
            success: true,
            guestId,
            qrCode: qrBase64,
            guest: { name: name.trim() },
        });

    } catch (err) {
        console.error('❌ QR generation error:', err);
        return res.status(500).json({
            success: false,
            error: err.message || 'Internal Server Error',
        });
    }
};

const getMyGuests = async (req, res) => {
    try {
        const { residentId } = req.params;

        const guests = await Guest.find({ residentId })
            .select('-qrCode')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            count: guests.length,
            guests,
        });

    } catch (err) {
        console.error('Get guests error:', err);
        return res.status(500).json({
            success: false,
            error: 'Failed to fetch guests',
        });
    }
};

const getGuestQR = async (req, res) => {
    try {
        const { guestId } = req.params;

        const guest = await Guest.findOne({ guestId });

        if (!guest) {
            return res.status(404).json({
                success: false,
                error: 'Guest pass not found',
            });
        }

        return res.status(200).json({
            success: true,
            guest,
        });

    } catch (err) {
        console.error('Get guest QR error:', err);
        return res.status(500).json({
            success: false,
            error: 'Failed to fetch guest QR',
        });
    }
};

module.exports = {
    generateGuestQR,
    getMyGuests,
    getGuestQR,
};