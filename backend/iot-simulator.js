const mqtt = require('mqtt');
const { v4: uuidv4 } = require('uuid');

// Configuration
const MQTT_BROKER = 'mqtt://localhost:1883';
const TOPIC_PREFIX = 'orelax/energy';

// Simulated devices
const devices = [
  { deviceId: uuidv4(), deviceName: 'Building A - Main Meter', location: 'Building A', type: 'electricity', baseConsumption: 45, variance: 15 },
  { deviceId: uuidv4(), deviceName: 'Building B - Main Meter', location: 'Building B', type: 'electricity', baseConsumption: 38, variance: 12 },
  { deviceId: uuidv4(), deviceName: 'Pool Pump', location: 'Pool Area', type: 'electricity', baseConsumption: 12, variance: 3 },
  { deviceId: uuidv4(), deviceName: 'Gym Equipment', location: 'Gym', type: 'electricity', baseConsumption: 8, variance: 4 },
  { deviceId: uuidv4(), deviceName: 'Water Main', location: 'Building A', type: 'water', baseConsumption: 120, variance: 30, unit: 'L' },
];

let client;

function connectMQTT() {
  client = mqtt.connect(MQTT_BROKER);
  
  client.on('connect', () => {
    console.log('✅ IoT Simulator connected to MQTT broker');
    startSimulation();
  });
  
  client.on('error', (err) => {
    console.error('❌ MQTT connection error:', err);
    console.log('⚠️ Make sure Mosquitto MQTT broker is running');
    console.log('   Install Mosquitto: https://mosquitto.org/download/');
  });
}

function startSimulation() {
  console.log('🔄 Starting energy data simulation...');
  
  // Send data every 5 seconds
  setInterval(() => {
    devices.forEach(device => {
      // Simulate time-of-day variation
      const hour = new Date().getHours();
      let multiplier = 1.0;
      
      // Peak hours (8-11 AM, 6-9 PM)
      if ((hour >= 8 && hour <= 11) || (hour >= 18 && hour <= 21)) {
        multiplier = 1.5;
      }
      // Night hours (11 PM - 5 AM)
      else if (hour >= 23 || hour <= 5) {
        multiplier = 0.3;
      }
      
      // Generate random consumption with time-based variation
      const randomFactor = 0.7 + Math.random() * 0.6;
      const consumption = device.baseConsumption * multiplier * randomFactor;
      const roundedConsumption = Math.round(consumption * 10) / 10;
      
      const reading = {
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        location: device.location,
        readingType: device.type,
        value: roundedConsumption,
        unit: device.unit || 'kWh',
        timestamp: new Date().toISOString(),
        isAlert: roundedConsumption > device.baseConsumption * 1.8,
        alertThreshold: device.baseConsumption * 1.8,
      };
      
      // Publish to MQTT topic
      const topic = `${TOPIC_PREFIX}/${device.type}/${device.deviceId}`;
      client.publish(topic, JSON.stringify(reading));
      console.log(`📤 Published to ${topic}: ${roundedConsumption} ${reading.unit}`);
    });
  }, 5000); // Every 5 seconds
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n👋 Shutting down IoT simulator...');
  if (client) client.end();
  process.exit();
});

connectMQTT();