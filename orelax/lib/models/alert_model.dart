import 'package:flutter/material.dart';

class Alert {
  final String id;
  final String title;
  final String message;
  final String category;
  final String subCategory;
  final String location;
  final String reportedBy;
  final DateTime createdAt;
  String status;
  final String reportId;
  bool isRead;
  final String alertType;
  final dynamic gasPpm;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.subCategory,
    required this.location,
    required this.reportedBy,
    required this.createdAt,
    required this.status,
    required this.reportId,
    this.isRead = false,
    this.alertType = 'report',
    this.gasPpm,
  });

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      location: map['location'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'pending',
      reportId: map['reportId'] ?? '',
      isRead: map['isRead'] ?? false,
      alertType: map['alertType'] ?? 'report',
      gasPpm: map['gasPpm'],
    );
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in-progress': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case 'pending': return 'Pending';
      case 'in-progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }
}