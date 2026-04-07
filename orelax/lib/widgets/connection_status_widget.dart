import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final Widget child;
  
  const ConnectionStatusWidget({super.key, required this.child});
  
  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isConnected = false;
  
  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Add periodic check
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _checkConnection();
      }
      return mounted;
    });
  }
  
  void _checkConnection() {
    final connected = ChatService.isConnected;
    if (connected != _isConnected) {
      setState(() {
        _isConnected = connected;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red,
              padding: const EdgeInsets.all(4),
              child: const Center(
                child: Text(
                  'Connecting to chat...',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}