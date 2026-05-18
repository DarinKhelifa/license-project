import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../screens/Home/home_screen.dart';
import '../screens/auth/otp_verification_screen.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isAdminRole(Map<String, dynamic>? user) {
    final role = (user?['role'] ?? '').toString().trim().toLowerCase();
    return role == 'admin';
  }

  Future<void> _denyAdminAccess(String message) async {
    await ApiService.removeToken();
    _user = null;
    _errorMessage = message;
  }

    String _friendlyAuthError(Object error, {required String fallback}) {
      final raw = error.toString();
      final message = raw.startsWith('Exception: ') ? raw.substring('Exception: '.length) : raw;
      final normalized = message.trim();

      if (normalized.contains('Please provide email and password')) {
        return 'Please enter both your email and password.';
      }
      if (normalized.contains('Invalid credentials')) {
        return 'The email or password you entered is incorrect.';
      }
      if (normalized.contains('Please verify your email address before logging in')) {
        return 'Please verify your email address before signing in.';
      }
      if (normalized.contains('Account is pending approval')) {
        return 'Your account is waiting for approval. Please try again later.';
      }
      if (normalized.contains('User already exists with this email')) {
        return 'An account already exists with this email address.';
      }
      if (normalized.contains('Failed to send verification email')) {
        return 'We could not send the verification email. Please try again.';
      }
      if (normalized.contains('Password must be at least 8 characters')) {
        return 'Your password must be at least 8 characters and include a letter, a number, and one symbol (._@).';
      }
      if (normalized.contains('Google Sign In coming soon')) {
        return 'Google sign-in is not available yet.';
      }
      if (normalized.contains('Password reset coming soon')) {
        return 'Password reset is not available yet.';
      }
      if (normalized.contains('Admin accounts must use the Dashboard')) {
        return 'Admin accounts must use the Dashboard, not the mobile app.';
      }

      return fallback;
    }
  
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
      final isEmailVerified = user['isEmailVerified'] == true;
      final status = (user['status'] ?? '').toString().toLowerCase();

      if (_isAdminRole(user)) {
        await _denyAdminAccess('Admin accounts must use the Dashboard, not the mobile app.');
      } else if (isEmailVerified && status == 'active') {
        _user = user;
        _errorMessage = null;
        await initializeChat();
      } else {
        await ApiService.removeToken();
        _user = null;
        _errorMessage = !isEmailVerified
            ? 'Please verify your email address before logging in.'
            : 'Account is pending approval. Please wait for admin approval.';
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

      if (_isAdminRole(_user)) {
        await _denyAdminAccess('Admin accounts must use the Dashboard, not the mobile app.');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (_user != null) {
        await initializeChat();
        _navigateAfterAuthentication(context);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
        _errorMessage = _friendlyAuthError(
          e,
          fallback: 'We could not sign you in. Please check your details and try again.',
        );
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

      if (_isAdminRole(_user)) {
        await _denyAdminAccess('Admin accounts must use the Dashboard, not the mobile app.');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
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
        _errorMessage = _friendlyAuthError(
          e,
          fallback: 'We could not create your account. Please review your information and try again.',
        );
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
      _errorMessage = _friendlyAuthError(
        e,
        fallback: 'We could not update your profile right now. Please try again.',
      );
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
        _errorMessage = _friendlyAuthError(
          e,
          fallback: 'We could not change your password right now. Please try again.',
        );
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