class Story {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool viewed;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    required this.viewed,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get timeUntilExpiry {
    if (isExpired) return 'Expired';
    final difference = expiresAt.difference(DateTime.now());
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    }
    return '${difference.inMinutes}m';
  }

  factory Story.fromMap(Map<String, dynamic> json) {
    return Story(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      userAvatar: json['userAvatar'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      viewed: json['viewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'imageUrl': imageUrl,
    };
  }
}
