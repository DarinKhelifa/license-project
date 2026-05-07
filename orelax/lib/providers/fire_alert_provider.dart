import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/socket_service.dart';

class FireAlert {
  final String id;
  final DateTime timestamp;
  String status; // 'active' or 'acknowledged'

  FireAlert({required this.id, required this.timestamp, this.status = 'active'});

  factory FireAlert.fromMap(Map<String, dynamic> map) {
    return FireAlert(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.parse(map['timestamp'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()),
      status: (map['status'] as String?) ?? 'active',
    );
  }
}

class FireAlertProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  List<FireAlert> _alerts = [];
  FireAlert? _active;

  List<FireAlert> get alerts => _alerts;
  FireAlert? get activeAlert => _active;

  FireAlertProvider() {
    _listenSocket();
  }

  void _listenSocket() {
    try {
      _socket_service_fire_listener:
      _socketService.fireAlertStream.listen((data) {
        final alert = FireAlert.fromMap(Map<String, dynamic>.from(data));
        _alerts.insert(0, alert);
        // If alert is active, show overlay
        if (alert.status.toLowerCase() == 'active') {
          _active = alert;
        }
        notifyListeners();
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchHistory() async {
    try {
      final resp = await http.get(Uri.parse('http://10.40.104.216:5000/api/iot/alerts'));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is List) {
          _alerts = body.map((e) => FireAlert.fromMap(Map<String, dynamic>.from(e))).toList();
        } else if (body is Map && body['alerts'] is List) {
          _alerts = (body['alerts'] as List).map((e) => FireAlert.fromMap(Map<String, dynamic>.from(e))).toList();
        }
        // sort newest first
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      // ignore errors for now
    }
  }

  void acknowledge(String id) {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx].status = 'acknowledged';
    }
    if (_active?.id == id) _active = null;
    notifyListeners();
  }
}
