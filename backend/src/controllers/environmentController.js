const EnvironmentReading = require('../models/EnvironmentReading');

const getCurrentReadings = async (req, res) => {
  try {
    const readings = await EnvironmentReading.aggregate([
      { $sort: { timestamp: -1 } },
      { $group: {
        _id: '$deviceId',
        deviceId: { $first: '$deviceId' },
        deviceName: { $first: '$deviceName' },
        location: { $first: '$location' },
        temperature: { $first: '$temperature' },
        humidity: { $first: '$humidity' },
        unitTemp: { $first: '$unitTemp' },
        unitHum: { $first: '$unitHum' },
        timestamp: { $first: '$timestamp' },
      }},
      { $sort: { deviceName: 1 } },
    ]);

    res.json(readings);
  } catch (error) {
    console.error('Get environment current readings error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getCurrentReadings,
};
