import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../screens/Home/home_screen.dart';
import '../screens/auth/otp_verification_screen.dart';

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
  
  Future<bool> signInWithEmail(
    String email,
    String password, {
    BuildContext? context,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await ApiService.login(email: email, password: password);
      _user = response['user'];
      
      if (_user != null) {
        await initializeChat();
        _navigateAfterAuthentication(context);
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
    required String phone,
    String? apartment,
    String? residence,
    String? building,
    String role = 'resident',
    BuildContext? context,
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
        apartment: apartment ?? '',
        residence: residence,
        building: building,
        role: role,
      );
      _user = response['user'];
      
      if (_user != null) {
        // Check if email is verified
        final isVerified = _user!['isEmailVerified'] ?? false;
        
        if (!isVerified && context != null && context.mounted) {
          // Navigate to OTP verification screen
          final userId = _user!['_id'] ?? _user!['id'];
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                userId: userId.toString(),
                email: email,
              ),
            ),
            (route) => false,
          );
        } else {
          // Email already verified or no context, proceed to home
          await initializeChat();
          _navigateAfterAuthentication(context);
        }
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

    if (data['photo'] != null) {
      updatedUser = await ApiService.updateProfileWithPhoto(
        name: data['name']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        apartment: data['apartment']?.toString() ?? '',
        photoFile: data['photo'],
      );
    } else {
      updatedUser = await ApiService.updateProfile(
        name: data['name']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        apartment: data['apartment']?.toString() ?? '',
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

  void _navigateAfterAuthentication(BuildContext? context) {
    if (context == null || !context.mounted || _user == null) {
      return;
    }

    final role = (_user!['role'] ?? 'resident').toString().trim().toLowerCase();
    final Widget targetScreen;

    if (role == 'security' || role == 'securite') {
      // HomeScreen is the security-equivalent landing page in this app.
      targetScreen = const HomeScreen();
    } else {
      targetScreen = const HomeScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => targetScreen),
      (route) => false,
    );
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