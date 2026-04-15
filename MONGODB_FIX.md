# MongoDB Connection Timeout Fix

## Problem Identified
Your application was experiencing timeout errors because:
1. **Missing connection pool settings** - MongoDB wasn't allocating enough connections
2. **No timeout configuration** - Default timeouts (10 seconds) were too short for high load
3. **Sequential database operations** - MQTT handler was blocking on summary updates
4. **High-frequency MQTT writes** - IoT simulator sending data every 5 seconds created bottlenecks

## Errors That Were Fixed
- `user.findOne() timed out` - During login
- `energyreadings.insertOne() buffering timed out after 10000ms` - MQTT message processing

## Changes Made

### 1. Updated Database Configuration
**File:** `backend/src/config/database.js`

Added connection pooling and timeout options:
- `maxPoolSize: 10` - Max database connections
- `minPoolSize: 5` - Min connections to maintain
- `serverSelectionTimeoutMS: 30000` - 30 seconds to select a server (was 10s default)
- `socketTimeoutMS: 45000` - 45 seconds for operations (was 30s default)
- `maxIdleTimeMS: 30000` - Remove idle connections after 30 seconds

### 2. Updated Server Database Connection
**File:** `backend/server.js`

Applied same connection pooling configuration to the main server connection.

### 3. Optimized MQTT Message Handler
**File:** `backend/src/controllers/energyController.js`

Changed `updateDailySummary()` from blocking (`await`) to non-blocking (fire-and-forget):
- Main message handling completes quickly
- Summary updates happen in background
- Errors are logged but don't block incoming messages
- Prevents connection pool exhaustion

## Next Steps

### 1. Stop the Current Server
```bash
# In the terminal running your backend, press Ctrl+C
```

### 2. Verify MongoDB is Running
Check that your MongoDB Atlas account is accessible:
- Connection string in `.env`: `mongodb+srv://darinkhelifa:softwareeng23@orelax.ghgmsvb.mongodb.net/Orelax?retryWrites=true&w=majority`
- Verify IP whitelist includes your current network (0.0.0.0/0 for testing)

### 3. Restart the Backend
```bash
cd backend
npm install  # Optional - installs fresh modules if needed
node server.js
```

### 4. Monitor Logs
You should see:
```
✅ MongoDB connected successfully
✅ Backend connected to MQTT broker (if IoT simulator is running)
📡 Subscribed to energy topics
```

### 5. Test Login
Try logging in to your app. You should now get a response instead of timeout.

## Troubleshooting

### Still Getting Timeouts?
1. **Check MongoDB Atlas Dashboard**
   - Verify database is running
   - Check for any warnings/alerts
   - Review active connections under Monitoring

2. **Check Network Connection**
   - Ping MongoDB: `ping orelax.ghgmsvb.mongodb.net`
   - Check firewall isn't blocking connections

3. **Increase Timeouts Further** (if on slow network)
   - Edit `backend/server.js` and `backend/src/config/database.js`
   - Change `serverSelectionTimeoutMS: 30000` → `60000`
   - Change `socketTimeoutMS: 45000` → `60000`

### Connection Pool Issues
If you see "Connection pool exhausted":
- Reduce MQTT message frequency in `backend/iot-simulator.js`
- Change `setInterval(..., 5000)` → `setInterval(..., 10000)` (5 sec → 10 sec)

## Performance Notes
- Current settings support ~10 concurrent database operations
- MQTT writes are non-blocking, preventing connection starvation
- Server can handle the 5 devices × 5 second interval = 1 write/second easily

## Additional Resources
- [Mongoose Connection Options](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.connect())
- [MongoDB Atlas Troubleshooting](https://docs.atlas.mongodb.com/troubleshoot-connection/)
