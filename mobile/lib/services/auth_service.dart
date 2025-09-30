import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();

  // Register new user
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        // Save auth tokens and user data
        final authData = response.data!;
        await _saveAuthData(authData);
      }

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Registration failed: ${e.toString()}',
        code: 'REGISTRATION_ERROR',
      );
    }
  }

  // Login user
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        // Save auth tokens and user data
        final authData = response.data!;
        await _saveAuthData(authData);
      }

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Login failed: ${e.toString()}',
        code: 'LOGIN_ERROR',
      );
    }
  }

  // Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _apiService.post<void>(
        ApiConfig.logout,
      );

      // Clear stored auth data regardless of API response
      await StorageService.clearAuthTokens();
      await StorageService.clearAllCachedData();

      return response.success
          ? response
          : ApiResponse.success(message: 'Logged out successfully');
    } catch (e) {
      // Still clear local data even if API call fails
      await StorageService.clearAuthTokens();
      await StorageService.clearAllCachedData();
      
      return ApiResponse.success(message: 'Logged out successfully');
    }
  }

  // Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiService.get<User>(
        ApiConfig.me,
        fromJson: (json) => User.fromJson(json['user']),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get user profile: ${e.toString()}',
        code: 'GET_USER_ERROR',
      );
    }
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile({
    String? username,
    String? profilePic,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (profilePic != null) data['profilePic'] = profilePic;

      final response = await _apiService.put<User>(
        ApiConfig.me,
        data: data,
        fromJson: (json) => User.fromJson(json['user']),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to update profile: ${e.toString()}',
        code: 'UPDATE_PROFILE_ERROR',
      );
    }
  }

  // Request password reset
  Future<ApiResponse<void>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _apiService.post<void>(
        ApiConfig.resetPassword,
        data: {'email': email},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to request password reset: ${e.toString()}',
        code: 'PASSWORD_RESET_REQUEST_ERROR',
      );
    }
  }

  // Reset password with token
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post<void>(
        '${ApiConfig.resetPassword}/$token',
        data: {'password': newPassword},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to reset password: ${e.toString()}',
        code: 'PASSWORD_RESET_ERROR',
      );
    }
  }

  // Refresh authentication token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        return ApiResponse.error(
          message: 'No refresh token available',
          code: 'NO_REFRESH_TOKEN',
        );
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        // Save new tokens
        final newToken = response.data!['token'];
        final newRefreshToken = response.data!['refreshToken'];
        
        await StorageService.saveAuthTokens(
          token: newToken,
          refreshToken: newRefreshToken,
        );
      }

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to refresh token: ${e.toString()}',
        code: 'REFRESH_TOKEN_ERROR',
      );
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await StorageService.hasAuthTokens();
  }

  // Validate current auth state
  Future<bool> validateAuthState() async {
    if (!await isAuthenticated()) {
      return false;
    }

    try {
      final response = await getCurrentUser();
      return response.success;
    } catch (e) {
      // Since refresh token is not implemented in backend,
      // we'll just clear auth data if validation fails
      print('Token validation failed: $e');
      await StorageService.clearAuthTokens();
      return false;
    }
  }

  // Helper method to save auth data
  Future<void> _saveAuthData(Map<String, dynamic> authData) async {
    // Backend returns tokens nested under 'tokens' object
    final tokens = authData['tokens'] as Map<String, dynamic>;
    final token = tokens['access'] as String;
    final refreshToken = tokens['refresh'] as String;
    final userData = authData['user'] as Map<String, dynamic>;

    await Future.wait([
      StorageService.saveAuthTokens(
        token: token,
        refreshToken: refreshToken,
      ),
      StorageService.saveUserData(
        userId: userData['_id'] ?? userData['id'],
        email: userData['email'],
      ),
    ]);
  }

  // Get stored user ID
  Future<String?> getCurrentUserId() async {
    return await StorageService.getUserId();
  }

  // Get stored user email
  Future<String?> getCurrentUserEmail() async {
    return await StorageService.getUserEmail();
  }

  // Clear all authentication data
  Future<void> clearAuthData() async {
    await StorageService.clearAuthTokens();
    await StorageService.clearAllCachedData();
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    // Minimum 6 characters as per backend requirements
    return password.length >= 6;
  }

  // Validate username format
  static bool isValidUsername(String username) {
    // 3-30 characters, alphanumeric + underscore and dash
    return RegExp(r'^[a-zA-Z0-9_-]{3,30}$').hasMatch(username);
  }

  // Get password strength score (0-4)
  static int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    return score;
  }

  // Get password strength text
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
      case 5:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }
}