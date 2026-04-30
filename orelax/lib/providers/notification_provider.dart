import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class NotificationProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> initialize(String serverUrl, String userId) async {
    try {
      await _socketService.connect(serverUrl, userId);
      _socketService.notificationStream.listen((notificationData) {
        _handleIncomingNotification(notificationData);
      });

      await fetchNotifications(userId);
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  Future<void> fetchNotifications(String userId) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notifications/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final notifications = responseBody['notifications'];
        if (notifications is List) {
          _notifications = notifications
              .map((n) => NotificationModel.fromJson(
                  Map<String, dynamic>.from(n as Map)))
              .toList();
          _updateUnreadCount();
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
    }
  }

  void _handleIncomingNotification(Map<String, dynamic> data) {
    final notification = NotificationModel.fromJson(data);
    _notifications.insert(0, notification);
    _updateUnreadCount();
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await ApiService.getToken();
      await http.patch(
        Uri.parse('${ApiService.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          isRead: true,
          createdAt: _notifications[index].createdAt,
          metadata: _notifications[index].metadata,
        );
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final token = await ApiService.getToken();
      await http.patch(
        Uri.parse('${ApiService.baseUrl}/notifications/read-all/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                isRead: true,
                createdAt: n.createdAt,
                metadata: n.metadata,
              ))
          .toList();

      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final token = await ApiService.getToken();
      await http.delete(
        Uri.parse('${ApiService.baseUrl}/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  void disconnect() {
    _socketService.disconnect();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
