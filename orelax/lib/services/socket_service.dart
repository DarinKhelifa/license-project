import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket _socket;
  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnected = false;

  SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  // Initialize socket connection
  Future<void> connect(String serverUrl, String userId) async {
    try {
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableReconnection()
            .disableAutoConnect()
            .build(),
      );

      _socket.on('connect', (_) {
        print('✅ Socket connected');
        _isConnected = true;
        // Join notification room with userId
        _socket.emit('join-notification-room', userId);
      });

      _socket.on('notification-received', (data) {
        print('📬 Notification received: $data');
        _notificationStream.add(Map<String, dynamic>.from(data));
      });

      _socket.on('disconnect', (_) {
        print('❌ Socket disconnected');
        _isConnected = false;
      });

      _socket.on('error', (error) {
        print('❌ Socket error: $error');
      });

      _socket.connect();
    } catch (e) {
      print('❌ Error connecting socket: $e');
    }
  }

  // Get notifications stream
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStream.stream;

  // Check if socket is connected
  bool get isConnected => _isConnected;

  // Disconnect socket
  void disconnect() {
    _socket.disconnect();
    _isConnected = false;
  }

  // Dispose resources
  void dispose() {
    _notificationStream.close();
    if (_isConnected) {
      disconnect();
    }
  }
}
