import 'package:flutter/material.dart';

class Report {
  final String id;
  final String category;
  final String subCategory;
  final String location;
  final String description;
  final String? photoBase64;
  final bool timeIsNow;
  final String? customTime;
  final String status;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  Report({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.location,
    required this.description,
    this.photoBase64,
    required this.timeIsNow,
    this.customTime,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      photoBase64: map['photoBase64'],
      timeIsNow: map['timeIsNow'] ?? true,
      customTime: map['customTime'],
      status: map['status'] ?? 'pending',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
      resolutionNotes: map['resolutionNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'subCategory': subCategory,
      'location': location,
      'description': description,
      'photoBase64': photoBase64,
      'timeIsNow': timeIsNow,
      'customTime': customTime,
      'status': status,
    };
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
      case 'pending': return 'Pending Review';
      case 'in-progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }
}