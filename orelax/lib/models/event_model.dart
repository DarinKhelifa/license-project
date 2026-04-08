import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final String? imageBase64;
  final int capacity;
  final int currentRegistrations;
  final String status;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final bool isActive;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    this.imageBase64,
    this.capacity = 0,
    this.currentRegistrations = 0,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.isActive = true,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      category: map['category'] ?? 'social',
      imageBase64: map['imageBase64'],
      capacity: map['capacity']?.toInt() ?? 0,
      currentRegistrations: map['currentRegistrations']?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      rejectionReason: map['rejectionReason'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'category': category,
      'imageBase64': imageBase64,
      'capacity': capacity,
      'currentRegistrations': currentRegistrations,
      'status': status,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'isActive': isActive,
    };
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get categoryIcon {
    switch (category) {
      case 'social':
        return '🎉';
      case 'sports':
        return '⚽';
      case 'educational':
        return '📚';
      case 'workshop':
        return '🔧';
      case 'festival':
        return '🎪';
      default:
        return '📅';
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'social':
        return const Color.fromRGBO(233, 30, 99, 1.0);
      case 'sports':
        return const Color.fromRGBO(76, 175, 80, 1.0);
      case 'educational':
        return const Color.fromRGBO(33, 150, 243, 1.0);
      case 'workshop':
        return const Color.fromRGBO(255, 152, 0, 1.0);
      case 'festival':
        return const Color.fromRGBO(156, 39, 176, 1.0);
      default:
        return const Color.fromRGBO(3, 72, 8, 1.0);
    }
  }
}