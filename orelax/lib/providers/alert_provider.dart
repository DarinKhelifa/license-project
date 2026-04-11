import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';

class AlertProvider extends ChangeNotifier {
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<Alert> get alerts => _alerts;
  List<Alert> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  AlertProvider() {
    _setupAlertListener();
    fetchAlerts();
  }

  void _setupAlertListener() {
    ChatService.addNewAlertListener((data) {
      final alert = Alert.fromMap(data);
      _alerts.insert(0, alert);
      notifyListeners();
      
      // Show notification
      _showNotification(alert);
    });
  }

  void _showNotification(Alert alert) {
    // You can use flutter_local_notifications package here
    print('🔔 ALERT: ${alert.title} - ${alert.message}');
  }

  Future<void> fetchAlerts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final reports = await ApiService.getReportsForRole();
      _alerts = reports.map((r) => Alert(
        id: r['id'],
        title: '${r['category']} Report',
        message: '${r['subCategory']} issue at ${r['location']}',
        category: r['category'],
        subCategory: r['subCategory'],
        location: r['location'],
        reportedBy: r['createdByName'],
        createdAt: DateTime.parse(r['createdAt']),
        status: r['status'],
        reportId: r['id'],
        isRead: false,
      )).toList();
    } catch (e) {
      _error = e.toString();
      print('Error fetching alerts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  void removeAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  Future<void> updateAlertStatus(String reportId, String newStatus) async {
    try {
      await ApiService.updateReportStatus(reportId, newStatus);
      
      // Update local alert
      final index = _alerts.indexWhere((a) => a.reportId == reportId);
      if (index != -1) {
        _alerts[index].status = newStatus;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating alert status: $e');
    }
  }
}