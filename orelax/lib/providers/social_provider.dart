import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/comment_model.dart';
import '../services/social_api_service.dart';

class SocialProvider extends ChangeNotifier {
  List<Post> _posts = [];
  List<Story> _stories = [];
  Map<String, List<Comment>> _comments = {};
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<Comment>> getComments(String postId) async {
    return _comments[postId] ?? [];
  }

  // Fetch posts
  Future<void> fetchPosts([int page = 1]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await SocialApiService.getPosts(page);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create post
  Future<bool> createPost({
    required String content,
    List<Uint8List>? images,
    List<String>? imageNames,
    List<Uint8List>? attachments,
    List<String>? attachmentNames,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPost = await SocialApiService.createPost(
        content: content,
        images: images,
        imageNames: imageNames,
        attachments: attachments,
        attachmentNames: attachmentNames,
      );
      _posts.insert(0, newPost);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating post: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete post
  Future<bool> deletePost(String postId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SocialApiService.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting post: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Like post
  Future<bool> likePost(String postId) async {
    try {
      final updatedPost = await SocialApiService.likePost(postId);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error liking post: $e');
      return false;
    }
  }

  // Add reaction to post
  Future<bool> addReaction(String postId, String emoji) async {
    try {
      final updatedPost = await SocialApiService.addReaction(postId, emoji);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding reaction: $e');
      return false;
    }
  }

  // Comments
  Future<void> fetchComments(String postId) async {
    try {
      final comments = await SocialApiService.getComments(postId);
      _comments[postId] = comments;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching comments: $e');
    }
  }

  Future<bool> addComment(String postId, String content) async {
    try {
      final comment = await SocialApiService.addComment(postId, content);
      if (_comments[postId] != null) {
        _comments[postId]!.add(comment);
      } else {
        _comments[postId] = [comment];
      }
      
      // Update post comment count
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = Post(
          id: post.id,
          userId: post.userId,
          userName: post.userName,
          userAvatar: post.userAvatar,
          content: post.content,
          imageUrls: post.imageUrls,
          attachmentUrls: post.attachmentUrls,
          createdAt: post.createdAt,
          likes: post.likes,
          comments: post.comments + 1,
          shares: post.shares,
          isLikedByCurrentUser: post.isLikedByCurrentUser,
          reactions: post.reactions,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  // Stories
  Future<void> fetchStories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stories = await SocialApiService.getStories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching stories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStory({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newStory = await SocialApiService.createStory(
        imageBytes: imageBytes,
        filename: filename,
      );
      _stories.insert(0, newStory);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating story: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Share post
  Future<bool> sharePost(String postId) async {
    try {
      await SocialApiService.sharePost(postId);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = Post(
          id: post.id,
          userId: post.userId,
          userName: post.userName,
          userAvatar: post.userAvatar,
          content: post.content,
          imageUrls: post.imageUrls,
          attachmentUrls: post.attachmentUrls,
          createdAt: post.createdAt,
          likes: post.likes,
          comments: post.comments,
          shares: post.shares + 1,
          isLikedByCurrentUser: post.isLikedByCurrentUser,
          reactions: post.reactions,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sharing post: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
