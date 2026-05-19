const WebSocket = require('ws');

let latestLiveReading = null;
let latestEnergyReading = null;

function normalizeSerialLine(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  try {
    const parsed = JSON.parse(trimmed);
    
    // Handle temperature/humidity sensor data
    if (parsed && parsed.type === 'wokwi-sensor') {
      const temperature = Number(parsed.temperature);
      const humidity = Number(parsed.humidity);

      if (Number.isFinite(temperature) && Number.isFinite(humidity)) {
        latestLiveReading = {
          deviceId: 'wokwi-simulator',
          deviceName: 'Wokwi Simulator',
          location: 'Live bridge',
          temperature,
          humidity,
          unitTemp: '°C',
          unitHum: '%',
          timestamp: new Date(),
        };
        console.log('Wokwi bridge parsed live reading:', latestLiveReading);
      }
    }
    
    // Handle energy data (electricity, water)
    if (parsed && parsed.type === 'wokwi-energy') {
      const electricity = Number(parsed.electricity);
      const water = Number(parsed.water);

      if ((Number.isFinite(electricity) || Number.isFinite(water))) {
        latestEnergyReading = {
          readings: [],
          timestamp: new Date(),
        };
        
        if (Number.isFinite(electricity)) {
          latestEnergyReading.readings.push({
            deviceId: 'wokwi-electricity',
            deviceName: 'Wokwi Electricity',
            readingType: 'electricity',
            value: electricity,
            unit: 'kWh',
            timestamp: new Date(),
          });
        }
        
        if (Number.isFinite(water)) {
          latestEnergyReading.readings.push({
            deviceId: 'wokwi-water',
            deviceName: 'Wokwi Water',
            readingType: 'water',
            value: water,
            unit: 'L',
            timestamp: new Date(),
          });
        }
        
        console.log('Wokwi bridge parsed energy reading:', latestEnergyReading);

        return latestEnergyReading;
      }
    }
  } catch (_) {
    // Ignore non-JSON serial lines.
  }

  return latestLiveReading || latestEnergyReading;
}

function handleWokwiMessage(socket, message, io) {
  let payload;

  try {
    payload = JSON.parse(message.toString());
  } catch (error) {
    console.log('Wokwi bridge received non-JSON message:', message.toString());
    return;
  }

  if (payload.cmd === 'aloha') {
    console.log('Wokwi bridge handshake received');
    socket.send(JSON.stringify({ cmd: 'serialMonitor' }));
    return;
  }

  if (payload.cmd === 'serialData') {
    const parsed = normalizeSerialLine(payload.value);
    if (parsed && io) {
      if (parsed.readings && Array.isArray(parsed.readings)) {
        for (const reading of parsed.readings) {
          io.emit('energy-update', {
            type: 'energy-update',
            data: reading,
          });
        }
      } else if (parsed.temperature != null || parsed.humidity != null) {
        io.emit('environment-update', {
          type: 'environment-update',
          data: parsed,
        });
      }
    }
  }
}

function startWokwiBridge(port = 2442, io = null) {
  const server = new WebSocket.Server({ port });

  server.on('connection', (socket) => {
    console.log(`Wokwi bridge client connected on ws://localhost:${port}`);

    socket.on('message', (message) => handleWokwiMessage(socket, message, io));

    socket.on('close', () => {
      console.log('Wokwi bridge client disconnected');
    });

    socket.on('error', (error) => {
      console.error('Wokwi bridge socket error:', error.message);
    });
  });

  server.on('listening', () => {
    console.log(`Wokwi bridge listening on ws://localhost:${port}`);
  });

  server.on('error', (error) => {
    console.error('Wokwi bridge server error:', error.message);
  });

  return server;
}

function getLatestLiveReading() {
  return latestLiveReading;
}

function getLatestEnergyReading() {
  return latestEnergyReading;
}

module.exports = {
  startWokwiBridge,
  getLatestLiveReading,
  getLatestEnergyReading,
};
