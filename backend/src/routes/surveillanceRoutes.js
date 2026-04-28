const WebSocket = require('ws');

const initSurveillance = (server) => {
    const wss = new WebSocket.Server({ server });

    wss.on('connection', (ws) => {
        console.log("🟢 Phone/Viewer connected to Surveillance Hub");

        ws.on('message', (data) => {
            // Relay frames from the Phone (IoT) to Chrome (Viewer)
            wss.clients.forEach((client) => {
                if (client !== ws && client.readyState === WebSocket.OPEN) {
                    client.send(data);
                }
            });
        });

        ws.on('close', () => console.log("🔴 Surveillance device disconnected"));
    });
};

module.exports = initSurveillance;