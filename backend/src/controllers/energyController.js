const EnergyReading = require('../models/EnergyReading');
const EnergyDailySummary = require('../models/EnergyDailySummary');
const mqtt = require('mqtt');

let mqttClient;

// Initialize MQTT connection
function initMQTT(io) {
  const MQTT_BROKER = 'mqtt://localhost:1883';
  const TOPIC_PATTERN = 'orelax/energy/#';
  
  
  mqttClient = mqtt.connect(MQTT_BROKER, {
    reconnectPeriod: 0, // disable auto-retry for now
  });
  
  mqttClient.on('connect', () => {
    console.log('✅ Backend connected to MQTT broker');
    mqttClient.subscribe(TOPIC_PATTERN, (err) => {
      if (!err) {
        console.log('📡 Subscribed to energy topics');
      }
    });
  });
  mqttClient.on('error', (err) => {
    console.warn('⚠️ MQTT unavailable - energy monitoring disabled');
    mqttClient.end(true); // stop completely
  });

  mqttClient.on('message', async (topic, message) => {
    try {
      const data = JSON.parse(message.toString());
      console.log(`📥 Received MQTT message: ${topic}`, data);
      
      // Save to database
      const reading = new EnergyReading(data);
      await reading.save();
      
      // Update daily summary (non-blocking - fire and forget)
      updateDailySummary(data).catch(err => {
        console.error('Error updating daily summary:', err);
      });
      
      // Emit via WebSocket to connected clients
      if (io) {
        io.emit('energy-update', data);
      }
      
      // Check for alert
      if (data.isAlert) {
        if (io) {
          const payload = {
            deviceName: data.deviceName,
            location: data.location,
            value: data.value,
            threshold: data.alertThreshold,
            timestamp: data.timestamp,
          };
          io.emit('energy-alert', payload);

          // Persist and emit notifications to maintenance and admin roles
          try {
            const { saveAndEmitToRole } = require('../helpers/notificationHelper');
            await saveAndEmitToRole(io, 'maintenance', {
              type: 'energy_alert',
              title: `Energy Alert: ${data.deviceName}`,
              body: `Device ${data.deviceName} at ${data.location} reported ${data.value} (threshold ${data.alertThreshold})`,
              metadata: { deviceId: data.deviceId }
            });
            await saveAndEmitToRole(io, 'admin', {
              type: 'energy_alert',
              title: `Energy Alert: ${data.deviceName}`,
              body: `Device ${data.deviceName} at ${data.location} reported ${data.value} (threshold ${data.alertThreshold})`,
              metadata: { deviceId: data.deviceId }
            });
          } catch (e) {
            console.error('Failed to persist/emit energy alert notifications', e);
          }
        }
      }
    } catch (err) {
      console.error('Error processing MQTT message:', err);
    }
  });
  
  mqttClient.on('error', (err) => {
    console.error('MQTT error:', err);
  });
}

async function updateDailySummary(reading) {
  const date = new Date().toISOString().split('T')[0];
  const hour = new Date().getHours();
  
  const summary = await EnergyDailySummary.findOne({
    deviceId: reading.deviceId,
    date: date,
  });
  
  if (summary) {
    // Update existing summary
    const hourlyData = summary.hourlyData || {};
    hourlyData[hour] = (hourlyData[hour] || 0) + reading.value;
    
    // Update total consumption
    const newTotal = summary.totalConsumption + reading.value;
    
    // Find new peak
    let peakHour = summary.peakHour;
    let peakValue = summary.peakValue;
    if (reading.value > peakValue) {
      peakHour = hour;
      peakValue = reading.value;
    }
    
    await EnergyDailySummary.updateOne(
      { deviceId: reading.deviceId, date: date },
      {
        totalConsumption: newTotal,
        peakHour: peakHour,
        peakValue: peakValue,
        averageHourly: newTotal / 24,
        hourlyData: hourlyData,
        $inc: { alerts: reading.isAlert ? 1 : 0 },
      }
    );
  } else {
    // Create new summary
    const hourlyData = {};
    hourlyData[hour] = reading.value;
    
    const newSummary = new EnergyDailySummary({
      deviceId: reading.deviceId,
      deviceName: reading.deviceName,
      location: reading.location,
      readingType: reading.readingType,
      date: date,
      totalConsumption: reading.value,
      peakHour: hour,
      peakValue: reading.value,
      averageHourly: reading.value / 24,
      hourlyData: hourlyData,
      alerts: reading.isAlert ? 1 : 0,
    });
    await newSummary.save();
  }
}

// API Controllers
const getCurrentReadings = async (req, res) => {
  try {
    // Get latest reading for each device
    const readings = await EnergyReading.aggregate([
      { $sort: { timestamp: -1 } },
      { $group: {
        _id: '$deviceId',
        deviceId: { $first: '$deviceId' },
        deviceName: { $first: '$deviceName' },
        location: { $first: '$location' },
        readingType: { $first: '$readingType' },
        value: { $first: '$value' },
        unit: { $first: '$unit' },
        timestamp: { $first: '$timestamp' },
      }},
      { $sort: { deviceName: 1 } },
    ]);
    
    res.json(readings);
  } catch (error) {
    console.error('Get current readings error:', error);
    res.status(500).json({ message: error.message });
  }
};

const getHistoricalData = async (req, res) => {
  try {
    const { deviceId, days = 7 } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    
    const query = { timestamp: { $gte: startDate } };
    if (deviceId) query.deviceId = deviceId;
    
    const readings = await EnergyReading.find(query)
      .sort({ timestamp: 1 })
      .limit(1000);
    
    // Group by hour for chart
    const hourlyData = {};
    readings.forEach(reading => {
      const hour = new Date(reading.timestamp).getHours();
      if (!hourlyData[hour]) {
        hourlyData[hour] = { total: 0, count: 0 };
      }
      hourlyData[hour].total += reading.value;
      hourlyData[hour].count++;
    });
    
    const chartData = Object.keys(hourlyData).map(hour => ({
      hour: parseInt(hour),
      average: hourlyData[hour].total / hourlyData[hour].count,
    })).sort((a, b) => a.hour - b.hour);
    
    res.json({
      readings,
      chartData,
      summary: {
        total: readings.reduce((sum, r) => sum + r.value, 0),
        average: readings.length ? readings.reduce((sum, r) => sum + r.value, 0) / readings.length : 0,
        peak: Math.max(...readings.map(r => r.value), 0),
      },
    });
  } catch (error) {
    console.error('Get historical data error:', error);
    res.status(500).json({ message: error.message });
  }
};

const getDeviceSummary = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const today = new Date().toISOString().split('T')[0];
    
    const todaySummary = await EnergyDailySummary.findOne({
      deviceId: deviceId,
      date: today,
    });
    
    const weeklyData = await EnergyDailySummary.find({
      deviceId: deviceId,
      date: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] },
    }).sort({ date: 1 });
    
    res.json({
      today: todaySummary,
      weekly: weeklyData,
    });
  } catch (error) {
    console.error('Get device summary error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  initMQTT,
  getCurrentReadings,
  getHistoricalData,
  getDeviceSummary,
};