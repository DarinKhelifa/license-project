import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  
  // Convenience getters for social features
  String? get userId => _user?['_id'] ?? _user?['id'];
  String? get userName => _user?['name'];
  String? get userAvatar => _user?['profileImage'];
  String? get userEmail => _user?['email'];
  
  AuthProvider() {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = await ApiService.getCurrentUser();
      _user = user;
      _errorMessage = null;
      
      if (_user != null) {
        await initializeChat();
      }
    } catch (e) {
      _user = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Initialize chat connection with user role
  Future<void> initializeChat() async {
    final id = userId;
    if (_user != null && id != null) {
      final role = (_user!['role'] ?? 'resident').toString();
      await ChatService.connect(id, role: role);
    }
  }
  
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await ApiService.login(email: email, password: password);
      _user = response['user'];
      
      if (_user != null) {
        await initializeChat();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String apartment,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        apartment: apartment,
      );
      _user = response['user'];
      
      if (_user != null) {
        await initializeChat();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> signInWithGoogle() async {
    _errorMessage = 'Google Sign In coming soon';
    notifyListeners();
    return false;
  }
  
  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = 'Password reset coming soon';
    notifyListeners();
    return false;
  }
  
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final updatedUser;
      
      // Check if photo is included in data
      if (data['photo'] != null) {
        // Use multipart upload method if photo is present
        updatedUser = await ApiService.updateProfileWithPhoto(
          name: data['name'],
          phone: data['phone'],
          apartment: data['apartment'],
          photoFile: data['photo'],
        );
      } else {
        // Use regular JSON update if no photo
        updatedUser = await ApiService.updateProfile(
          name: data['name'],
          phone: data['phone'],
          apartment: data['apartment'],
        );
      }
      
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    return _user;
  }
  
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    ChatService.disconnect();
    
    await ApiService.logout();
    _user = null;
    
    _isLoading = false;
    notifyListeners();
  }
}