import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_app/models/user.dart';
import 'package:dms_app/core/constants/app_constants.dart';

/// Authentication Service Provider
/// 
/// TODO: [PLACEHOLDER] Replace mock authentication with Firebase Auth
/// TODO: [PLACEHOLDER] Add Google Sign-In
/// TODO: [PLACEHOLDER] Add Apple Sign-In
/// TODO: [PLACEHOLDER] Add password reset functionality
/// TODO: [PLACEHOLDER] Add email verification
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  /// Mock login - replace with Firebase Auth
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: [PLACEHOLDER] Replace with Firebase Auth signInWithEmailAndPassword
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        _error = 'Email and password are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create mock user based on email pattern
      final isDoctor = email.contains('doctor') || email.contains('dr');
      _currentUser = User(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: isDoctor ? 'Dr. Jan Kowalski' : 'Anna Nowak',
        role: isDoctor ? AppConstants.roleDoctor : AppConstants.rolePatient,
        createdAt: DateTime.now(),
      );

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyUserRole, _currentUser!.role);
      await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
      await prefs.setString(AppConstants.keyUserName, _currentUser!.name);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mock registration - replace with Firebase Auth
  Future<bool> register(String email, String password, String name, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: [PLACEHOLDER] Replace with Firebase Auth createUserWithEmailAndPassword
      // TODO: [PLACEHOLDER] Save user data to Firestore
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        _error = 'All fields are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = User(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyUserRole, role);
      await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
      await prefs.setString(AppConstants.keyUserName, name);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    // TODO: [PLACEHOLDER] Add Firebase signOut
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);
    
    _currentUser = null;
    notifyListeners();
  }

  /// Check if user is logged in from SharedPreferences
  Future<bool> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    
    if (isLoggedIn) {
      // TODO: [PLACEHOLDER] Fetch user data from Firebase
      final role = prefs.getString(AppConstants.keyUserRole) ?? AppConstants.rolePatient;
      final userId = prefs.getString(AppConstants.keyUserId) ?? '';
      final userName = prefs.getString(AppConstants.keyUserName) ?? '';
      
      _currentUser = User(
        id: userId,
        email: 'restored@example.com',
        name: userName,
        role: role,
      );
      notifyListeners();
    }
    
    return isLoggedIn;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
