import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/socket_service.dart';
import '../services/api_service.dart';

class FireAlert {
  final String id;
  final DateTime timestamp;
  final String? location;
  String status; // 'active' or 'acknowledged'

  FireAlert({required this.id, required this.timestamp, this.location, this.status = 'active'});

  factory FireAlert.fromMap(Map<String, dynamic> map) {
    String id = map['id']?.toString() ?? map['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    dynamic ts = map['timestamp'] ?? map['createdAt'];

    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        if (value is DateTime) return value;
        if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
        if (value is String) return DateTime.parse(value);
        if (value is Map) {
          // Handle MongoDB extended JSON like { "$date": "2023-..." } or {"$date": {"$numberLong":"..."}}
          if (value.containsKey(r'\$date')) {
            final d = value[r'\$date'];
            if (d is String) return DateTime.parse(d);
            if (d is Map && d.containsKey(r'\$numberLong')) {
              final nl = d[r'\$numberLong'];
              return DateTime.fromMillisecondsSinceEpoch(int.parse(nl.toString()));
            }
          }
          // Fallback: try toString()
          return DateTime.parse(value.toString());
        }
        // Fallback
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return FireAlert(
      id: id,
      timestamp: parseTimestamp(ts ?? DateTime.now().toIso8601String()),
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

  bool get isHandlingAlert => _active != null && _active!.status.toLowerCase() == 'active';

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
      final url = '${ApiService.baseUrl}/iot/alerts';
      print('📡 Fetching fire alert history from $url');
      final resp = await http.get(Uri.parse(url));
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
      print('❌ Error fetching fire alert history: $e');
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

  void markSafe(String id) {
    acknowledge(id);
  }

  Future<void> reportNotSafe(String id, [Object? _]) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx].status = 'not_safe';
    }
    if (_active?.id == id) {
      _active = _alerts[idx != -1 ? idx : 0];
    }
    notifyListeners();
  }

  /// Create an alert programmatically (used for uncaught errors or manual triggers)
  void createErrorAlert(String message) {
    final alert = FireAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      location: message,
      status: 'active',
    );
    _alerts.insert(0, alert);
    _active = alert;
    notifyListeners();
  }
}
