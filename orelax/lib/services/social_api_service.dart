import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/comment_model.dart';

class SocialApiService {
  static const String baseUrl = 'http://localhost:5001/api';
  static const Duration httpTimeout = Duration(seconds: 30);

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await _getToken();
    final headers = {
      if (!isMultipart) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return headers;
  }

  // Posts
  static Future<List<Post>> getPosts([int page = 1]) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/social/posts?page=$page&limit=10'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final posts = (data['posts'] as List?)
            ?.map((json) => Post.fromMap(json))
            .toList() ?? [];
        return posts;
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Post> createPost({
    required String content,
    List<Uint8List>? images,
    List<String>? imageNames,
    List<Uint8List>? attachments,
    List<String>? attachmentNames,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/social/posts'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['content'] = content;

      // Add images
      if (images != null) {
        for (var i = 0; i < images.length; i++) {
          final image = images[i];
          final imageName = imageNames != null && imageNames.length > i ? imageNames[i] : 'image_$i.jpg';
          request.files.add(http.MultipartFile.fromBytes(
            'images',
            image,
            filename: imageName,
            contentType: _mediaTypeFromFilename(imageName),
          ));
        }
      }

      // Add attachments
      if (attachments != null) {
        for (var i = 0; i < attachments.length; i++) {
          final attachment = attachments[i];
          final attachmentName = attachmentNames != null && attachmentNames.length > i ? attachmentNames[i] : 'attachment_$i.bin';
          request.files.add(http.MultipartFile.fromBytes(
            'attachments',
            attachment,
            filename: attachmentName,
            contentType: MediaType('application', 'octet-stream'),
          ));
        }
      }

      final streamedResponse = await request.send().timeout(httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Post.fromMap(data['post']);
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      rethrow;
    }
  }

  static MediaType _mediaTypeFromFilename(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  static Future<void> deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/social/posts/$postId'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Post> likePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/$postId/like'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Post.fromMap(data['post']);
      } else {
        throw Exception('Failed to like post');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Post> addReaction(String postId, String emoji) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/$postId/react'),
        headers: await _getHeaders(),
        body: jsonEncode({'emoji': emoji}),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Post.fromMap(data['post']);
      } else {
        throw Exception('Failed to add reaction');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Comments
  static Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/social/posts/$postId/comments'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final comments = (data['comments'] as List?)
            ?.map((json) => Comment.fromMap(json))
            .toList() ?? [];
        return comments;
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Comment> addComment(String postId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/$postId/comments'),
        headers: await _getHeaders(),
        body: jsonEncode({'content': content}),
      ).timeout(httpTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Comment.fromMap(data['comment']);
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteComment(String postId, String commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/social/posts/$postId/comments/$commentId'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Stories
  static Future<List<Story>> getStories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/social/stories'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stories = (data['stories'] as List?)
            ?.map((json) => Story.fromMap(json))
            .toList() ?? [];
        return stories;
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      rethrow;
    }
  }

  static MediaType _storyMediaTypeFromFilename(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  static Future<Story> createStory({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/social/stories'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
        contentType: _storyMediaTypeFromFilename(filename),
      ));

      final streamedResponse = await request.send().timeout(httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Story.fromMap(data['story']);
      } else {
        final message = _extractErrorMessage(response.body);
        throw Exception(message ?? 'Failed to create story');
      }
    } catch (e) {
      rethrow;
    }
  }

  static String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['error'] ?? decoded['message'])?.toString();
      }
    } catch (_) {
      // ignore non-JSON body
    }
    return null;
  }

  static Future<void> sharePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/$postId/share'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to share post');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> sharePostWithUser(String postId, String recipientUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/$postId/share-with-user'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'recipientUserId': recipientUserId,
        }),
      ).timeout(httpTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to share post');
      }
    } catch (e) {
      rethrow;
    }
  }
}
