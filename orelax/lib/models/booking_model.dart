class Booking {
  final String id;
  final String facilityId;
  final String userId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final int duration; // in hours
  final double totalPrice;
  final String status; // pending, confirmed, cancelled
  final String userName;
  final String userEmail;
  final String userPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.facilityId,
    required this.userId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.totalPrice,
    required this.status,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromMap(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      facilityId: json['facilityId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      bookingDate: json['bookingDate'] != null 
          ? DateTime.parse(json['bookingDate'] as String)
          : DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'facilityId': facilityId,
    'userId': userId,
    'bookingDate': bookingDate.toIso8601String(),
    'startTime': startTime,
    'endTime': endTime,
    'duration': duration,
    'totalPrice': totalPrice,
    'status': status,
    'userName': userName,
    'userEmail': userEmail,
    'userPhone': userPhone,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
