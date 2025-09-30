import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get state => _state;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated && _currentUser != null;

  // Initialize and check auth state
  Future<void> checkAuthState() async {
    _setLoading(true);
    
    try {
      final isValid = await _authService.validateAuthState();
      
      if (isValid) {
        final userResponse = await _authService.getCurrentUser();
        if (userResponse.success && userResponse.data != null) {
          _currentUser = userResponse.data;
          _setState(AuthState.authenticated);
        } else {
          _setState(AuthState.unauthenticated);
        }
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Failed to validate authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        final userData = response.data!['user'];
        _currentUser = User.fromJson(userData);
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        final userData = response.data!['user'];
        _currentUser = User.fromJson(userData);
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      print('Logout error: $e');
      // Continue with logout even if API call fails
    }

    _currentUser = null;
    _setState(AuthState.unauthenticated);
    _setLoading(false);
  }

  // Update profile
  Future<bool> updateProfile({
    String? username,
    String? profilePic,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.updateProfile(
        username: username,
        profilePic: profilePic,
      );

      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.requestPasswordReset(email: email);

      if (response.success) {
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to request password reset: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to reset password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    try {
      final response = await _authService.getCurrentUser();
      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to refresh user data: $e');
    }
  }

  // Update user online status
  void updateUserOnlineStatus(bool isOnline) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        isOnline: isOnline,
        lastSeen: isOnline ? null : DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Get current user ID
  String? get currentUserId => _currentUser?.id;

  // Get current user email
  String? get currentUserEmail => _currentUser?.email;

  // Get current username
  String? get currentUsername => _currentUser?.username;

  // Get current user avatar
  String? get currentUserAvatar => _currentUser?.profilePic;

  // Validation methods
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    if (!AuthService.isValidEmail(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (!AuthService.isValidPassword(password)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }
    if (!AuthService.isValidUsername(username)) {
      return 'Username must be 3-30 characters with only letters, numbers, _ and -';
    }
    return null;
  }

  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Password strength
  int getPasswordStrength(String password) {
    return AuthService.getPasswordStrength(password);
  }

  String getPasswordStrengthText(String password) {
    final strength = getPasswordStrength(password);
    return AuthService.getPasswordStrengthText(strength);
  }

  Color getPasswordStrengthColor(String password) {
    final strength = getPasswordStrength(password);
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Private helper methods
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = AuthState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.initial;
    }
    notifyListeners();
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    _currentUser = null;
    _errorMessage = null;
    _setState(AuthState.unauthenticated);
    await _authService.clearAuthData();
  }

  // Auto-refresh token mechanism
  Future<bool> _refreshTokenIfNeeded() async {
    try {
      final response = await _authService.refreshToken();
      return response.success;
    } catch (e) {
      print('Token refresh failed: $e');
      return false;
    }
  }

  // Check if token needs refresh (call this periodically)
  Future<void> checkTokenValidity() async {
    if (!isAuthenticated) return;

    try {
      final response = await _authService.getCurrentUser();
      if (!response.success) {
        // Try to refresh token
        final refreshed = await _refreshTokenIfNeeded();
        if (!refreshed) {
          // If refresh fails, logout user
          await logout();
        }
      }
    } catch (e) {
      print('Token validation error: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}