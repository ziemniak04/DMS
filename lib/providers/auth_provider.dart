import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_app/models/user.dart';
import 'package:dms_app/core/constants/app_constants.dart';
import 'package:dms_app/services/firebase_auth_service.dart';
import 'package:dms_app/services/firestore_service.dart';
import 'package:dms_app/services/mock_data_service.dart';

/// Authentication Service Provider
///
/// Manages user authentication state using Firebase Auth
class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        // Check if this is a mock account that needs data generation BEFORE fetching from Firestore
        if (firebaseUser.email == MockDataService.mockEmail) {
          // For mock accounts, create a basic User object without Firestore document
          _currentUser = User(
            id: firebaseUser.uid,
            email: firebaseUser.email!,
            name: 'Mock Patient',
            role: 'patient',
            createdAt: DateTime.now(),
            diabetesType: 'Type 1',
          );

          // Create user document in Firestore for the mock account (needed for security rules)
          try {
            await _firestoreService.createUser(_currentUser!);
          } catch (e) {
            debugPrint('Error creating Firestore document for mock user: $e');
            // Continue anyway - the user object exists in memory
          }

          // Check if mock data already exists
          try {
            if (!await MockDataService.hasMockData(firebaseUser.uid)) {
              await MockDataService.generateMockData(firebaseUser.uid);
            }
          } catch (e) {
            debugPrint('Error checking/generating mock data: $e');
          }

          notifyListeners();
          return;
        }

        // For regular users, fetch from Firestore
        try {
          _currentUser = await _firestoreService.getUserById(firebaseUser.uid);
          notifyListeners();
        } catch (e) {
          _error = 'Error fetching user data';
          notifyListeners();
        }
      } else {
        // User is signed out
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        _error = 'Email and password are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Normal Firebase Auth flow (including mock account)
      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (_currentUser != null) {

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keyIsLoggedIn, true);
        await prefs.setString(AppConstants.keyUserRole, _currentUser!.role);
        await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
        await prefs.setString(AppConstants.keyUserName, _currentUser!.name);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register with email and password
  Future<bool> register(String email, String password, String name, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        _error = 'All fields are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (_currentUser != null) {
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keyIsLoggedIn, true);
        await prefs.setString(AppConstants.keyUserRole, role);
        await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
        await prefs.setString(AppConstants.keyUserName, name);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);

    _currentUser = null;
    notifyListeners();
  }

  /// Check if user is logged in
  Future<bool> checkAuthState() async {
    final firebaseUser = _authService.currentFirebaseUser;

    if (firebaseUser != null) {
      try {
        _currentUser = await _firestoreService.getUserById(firebaseUser.uid);
        notifyListeners();
        return true;
      } catch (e) {
        _error = 'Error fetching user data';
        notifyListeners();
        return false;
      }
    }

    return false;
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
