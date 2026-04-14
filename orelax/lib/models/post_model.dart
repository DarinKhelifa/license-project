import 'package:intl/intl.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final List<String> imageUrls;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final int shares;
  final bool isLikedByCurrentUser;
  final List<String> reactions; // emoji reactions

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.imageUrls,
    required this.attachmentUrls,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isLikedByCurrentUser,
    required this.reactions,
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(createdAt);
    }
  }

  factory Post.fromMap(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      userAvatar: json['userAvatar'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      attachmentUrls: List<String>.from(json['attachmentUrls'] as List? ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      reactions: List<String>.from(json['reactions'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'attachmentUrls': attachmentUrls,
    };
  }
}
