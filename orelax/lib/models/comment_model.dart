class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  final int likes;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    required this.likes,
  });

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  factory Comment.fromMap(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      userAvatar: json['userAvatar'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likes: json['likes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
    };
  }
}
