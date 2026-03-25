import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  
  AuthProvider() {
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn();
    }

    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      print('Auth state changed: user = ${user?.email ?? "null"}');
      notifyListeners();
    });
  }
  
  // Email Sign In
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    print('Attempting sign in with email: $email');
    
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('Sign in successful: ${result.user?.email}');
      return true;
      
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Email Sign Up
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
    
    print('Attempting sign up with email: $email');
    
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('User created: ${result.user?.uid}');
      
      await result.user!.updateDisplayName(name);
      await result.user!.reload();
      
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email.trim(),
        'phone': phone,
        'apartment': apartment,
        'role': 'resident',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User data saved to Firestore');
      
      return true;
      
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    print('Attempting Google Sign In');
    
    try {
      late final UserCredential result;
      
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        result = await _auth.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        
        if (googleUser == null) {
          print('Google sign in canceled by user');
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        print('Google user: ${googleUser.email}');
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        result = await _auth.signInWithCredential(credential);
      }
      
      print('Firebase sign in successful: ${result.user?.email}');
      
      final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
      if (!userDoc.exists) {
        print('New user, creating Firestore document');
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'name': result.user!.displayName ?? '',
          'email': result.user!.email ?? '',
          'phone': '',
          'apartment': '',
          'role': 'resident',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
      
    } catch (e) {
      print('Google sign in error: $e');
      _errorMessage = 'Google sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Send Password Reset Email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      print('Password reset error: $e');
      return false;
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await _googleSignIn?.signOut();
    await _auth.signOut();
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
  
  // Update user data in Firestore
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) return false;
    
    try {
      await _firestore.collection('users').doc(_user!.uid).update(data);
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }
  
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed: $code';
    }
  }
}