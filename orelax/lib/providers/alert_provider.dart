import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/alert_model.dart';

class AlertProvider extends ChangeNotifier {
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<Alert> get alerts => _alerts;
  List<Alert> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  AlertProvider() {
    _setupListeners();
    fetchAlerts();
  }

  void _setupListeners() {
    // Listen for new alerts from WebSocket
    ChatService.addNewAlertListener((alertData) {
      final alert = Alert(
        id: alertData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: alertData['title'] ?? 'New Alert',
        message: alertData['message'] ?? '',
        category: alertData['category'] ?? 'Security',
        subCategory: alertData['subCategory'] ?? 'Alert',
        location: alertData['location'] ?? 'Unknown',
        reportedBy: alertData['reportedBy'] ?? 'System',
        createdAt: DateTime.parse(alertData['timestamp'] ?? DateTime.now().toIso8601String()),
        status: 'pending',
        reportId: alertData['id'] ?? '',
        alertType: alertData['alertType'] ?? 'report',
        gasPpm: alertData['gasPpm'],
        isRead: false,
      );
      _alerts.insert(0, alert);
      notifyListeners();
    });

    // Listen for gas updates - TODO: Implement gas listener in ChatService
    // ChatService.addGasUpdateListener((data) {
    //   print('Gas update received: $data');
    //   // Optionally create an alert for warning/danger levels
    //   if (data['status'] == 'danger') {
    //     // Auto-create alert for dangerous gas levels
    //     final alert = Alert(
    //       id: DateTime.now().millisecondsSinceEpoch.toString(),
    //       title: '⚠️ GAS LEAK DETECTED!',
    //       message: 'Gas concentration at ${data['gas_ppm']} ppm - DANGER LEVEL!',
    //       category: 'Safety',
    //       subCategory: 'Gas Leak',
    //       location: 'Building A - Kitchen',
    //       reportedBy: 'Gas Sensor',
    //       createdAt: DateTime.now(),
    //       status: 'pending',
    //       reportId: '',
    //       alertType: 'gas',
    //       gasPpm: data['gas_ppm'],
    //       isRead: false,
    //     );
    //     _alerts.insert(0, alert);
    //     notifyListeners();
    //   }
    // });
  }

  Future<void> fetchAlerts() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate fetching alerts from API
    // In production, fetch from your backend
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index].isRead = true;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var alert in _alerts) {
      alert.isRead = true;
    }
    notifyListeners();
  }

  Future<void> updateAlertStatus(String reportId, String newStatus) async {
    final index = _alerts.indexWhere(
      (a) => a.reportId == reportId || a.id == reportId,
    );
    if (index == -1) return;

    final existing = _alerts[index];
    _alerts[index] = Alert(
      id: existing.id,
      title: existing.title,
      message: existing.message,
      category: existing.category,
      subCategory: existing.subCategory,
      location: existing.location,
      reportedBy: existing.reportedBy,
      createdAt: existing.createdAt,
      status: newStatus,
      reportId: existing.reportId,
      alertType: existing.alertType,
      gasPpm: existing.gasPpm,
      isRead: existing.isRead,
    );
    notifyListeners();
  }
}