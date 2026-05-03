import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/comment_model.dart';

class SocialApiService {
  static const String baseUrl = 'http://localhost:5000/api';
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
    List<File>? images,
    List<File>? attachments,
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
        for (final image in images) {
          request.files.add(await http.MultipartFile.fromPath(
            'images',
            image.path,
            contentType: MediaType('image', image.path.split('.').last),
          ));
        }
      }

      // Add attachments
      if (attachments != null) {
        for (final attachment in attachments) {
          request.files.add(await http.MultipartFile.fromPath(
            'attachments',
            attachment.path,
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

  static Future<Story> createStory(File image) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/social/stories'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType('image', image.path.split('.').last),
      ));

      final streamedResponse = await request.send().timeout(httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Story.fromMap(data['story']);
      } else {
        throw Exception('Failed to create story');
      }
    } catch (e) {
      rethrow;
    }
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
}
