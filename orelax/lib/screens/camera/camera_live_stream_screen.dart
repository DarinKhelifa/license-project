import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import
import 'dart:io'; // Add this import
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:typed_data';

class CameraLiveStreamScreen extends StatefulWidget {
  const CameraLiveStreamScreen({super.key});

  @override
  State<CameraLiveStreamScreen> createState() => _CameraLiveStreamScreenState();
}

class _CameraLiveStreamScreenState extends State<CameraLiveStreamScreen> {
  WebSocketChannel? _channel;
  Uint8List? _currentFrame;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _statusMessage = 'Disconnected';
  int _totalFrames = 0;

  // Update this with your server IP address
  final String _serverUrl = kIsWeb
      ? 'ws://localhost:8080'
      : (Platform.isAndroid ? 'ws://10.0.2.2:8080' : 'ws://192.168.1.100:8080');

  @override
  void initState() {
    super.initState();
    _connectToCamera();
  }

  Future<void> _connectToCamera() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting...';
    });

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));

      _channel!.stream.listen(
        (message) {
          if (message is String) {
            _handleTextMessage(message);
          } else if (message is Uint8List) {
            setState(() {
              _currentFrame = message;
              _totalFrames++;
              _statusMessage = 'Live';
            });
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _isConnected = false;
            _isConnecting = false;
            _statusMessage = 'Connection error';
          });
          _showSnackBar('Connection failed: $error');
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _isConnecting = false;
            _statusMessage = 'Disconnected';
          });
          _attemptReconnection();
        },
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final registerMsg = {
        'type': 'register',
        'role': 'viewer',
        'deviceId': 'flutter_app_001'
      };
      _channel?.sink.add(registerMsg.toString());

      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _statusMessage = 'Connected';
      });

      _showSnackBar('Connected to camera');
    } catch (e) {
      print('Connection error: $e');
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _statusMessage = 'Connection failed';
      });
      _attemptReconnection();
    }
  }

  void _handleTextMessage(String message) {
    print('Received: $message');
  }

  void _attemptReconnection() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected && mounted) {
        _connectToCamera();
      }
    });
  }

  void _disconnect() {
    _channel?.sink.close();
    setState(() {
      _isConnected = false;
      _statusMessage = 'Disconnected';
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Camera'),
        backgroundColor: const Color(0xFF1A5C2A),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera feed
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              child: Center(
                child: _currentFrame != null
                    ? InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.memory(
                          _currentFrame!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : _isConnecting
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF1A5C2A),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Connecting to camera...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No video feed',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
              ),
            ),
          ),

          // Control panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.video_call,
                        'Frames',
                        '$_totalFrames',
                      ),
                      _buildStatItem(
                        Icons.speed,
                        'Status',
                        _isConnected ? 'Live' : 'Offline',
                      ),
                      _buildStatItem(
                        Icons.wifi,
                        'Connection',
                        _isConnected ? 'Connected' : 'Disconnected',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Control buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isConnected ? _disconnect : _connectToCamera,
                        icon:
                            Icon(_isConnected ? Icons.stop : Icons.play_arrow),
                        label:
                            Text(_isConnected ? 'Stop Stream' : 'Start Stream'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected
                              ? Colors.red
                              : const Color(0xFF1A5C2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentFrame = null;
                          });
                          _showSnackBar('Stream cleared');
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A5C2A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF1A5C2A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap and pinch to zoom • Auto-reconnect enabled',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1A5C2A), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
