class NotificationModel {
  final String id;
  final String type; // 'staff_added', 'event_approved', 'message_received'
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final NotificationMetadata? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] != null
          ? NotificationMetadata.fromJson(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata?.toJson(),
    };
  }
}

class NotificationMetadata {
  final String? staffName;
  final String? staffRole;
  final String? eventTitle;
  final DateTime? eventDate;
  final String? eventLocation;
  final String? senderName;
  final String? senderPreview;
  final String? messageId;

  NotificationMetadata({
    this.staffName,
    this.staffRole,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.senderName,
    this.senderPreview,
    this.messageId,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      staffName: json['staffName'],
      staffRole: json['staffRole'],
      eventTitle: json['eventTitle'],
      eventDate:
          json['eventDate'] != null ? DateTime.parse(json['eventDate']) : null,
      eventLocation: json['eventLocation'],
      senderName: json['senderName'],
      senderPreview: json['senderPreview'],
      messageId: json['messageId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffName': staffName,
      'staffRole': staffRole,
      'eventTitle': eventTitle,
      'eventDate': eventDate?.toIso8601String(),
      'eventLocation': eventLocation,
      'senderName': senderName,
      'senderPreview': senderPreview,
      'messageId': messageId,
    };
  }
}
