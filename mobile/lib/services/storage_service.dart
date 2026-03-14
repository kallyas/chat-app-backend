import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static SharedPreferences? _prefs;

  // Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure Storage Keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Preferences Keys
  static const String _themeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Auth Token Management
  static Future<void> saveAuthTokens({
    required String token,
    required String refreshToken,
  }) async {
    await _writeSecureValue(_tokenKey, token);
    await _writeSecureValue(_refreshTokenKey, refreshToken);
    await Future.wait([
      _prefs?.setString(_tokenKey, token) ?? Future.value(true),
      _prefs?.setString(_refreshTokenKey, refreshToken) ?? Future.value(true),
    ]);
  }

  static Future<String?> getAuthToken() async {
    return _readAuthValue(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return _readAuthValue(_refreshTokenKey);
  }

  static Future<void> clearAuthTokens() async {
    await Future.wait([
      _deleteSecureValue(_tokenKey),
      _deleteSecureValue(_refreshTokenKey),
      _deleteSecureValue(_userIdKey),
      _deleteSecureValue(_userEmailKey),
      _prefs?.remove(_tokenKey) ?? Future.value(true),
      _prefs?.remove(_refreshTokenKey) ?? Future.value(true),
      _prefs?.remove(_userIdKey) ?? Future.value(true),
      _prefs?.remove(_userEmailKey) ?? Future.value(true),
    ]);
  }

  // User Data Management
  static Future<void> saveUserData({
    required String userId,
    required String email,
  }) async {
    await _writeSecureValue(_userIdKey, userId);
    await _writeSecureValue(_userEmailKey, email);
    await Future.wait([
      _prefs?.setString(_userIdKey, userId) ?? Future.value(true),
      _prefs?.setString(_userEmailKey, email) ?? Future.value(true),
    ]);
  }

  static Future<String?> getUserId() async {
    return _readAuthValue(_userIdKey);
  }

  static Future<String?> getUserEmail() async {
    return _readAuthValue(_userEmailKey);
  }

  // App Preferences
  static Future<void> setThemeMode(String themeMode) async {
    await _prefs?.setString(_themeKey, themeMode);
  }

  static String getThemeMode() {
    return _prefs?.getString(_themeKey) ?? 'system';
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_notificationsKey, enabled);
  }

  static bool getNotificationsEnabled() {
    return _prefs?.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_soundKey, enabled);
  }

  static bool getSoundEnabled() {
    return _prefs?.getBool(_soundKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs?.setBool(_vibrationKey, enabled);
  }

  static bool getVibrationEnabled() {
    return _prefs?.getBool(_vibrationKey) ?? true;
  }

  // Sync Management
  static Future<void> setLastSyncTimestamp(int timestamp) async {
    await _prefs?.setInt(_lastSyncKey, timestamp);
  }

  static int getLastSyncTimestamp() {
    return _prefs?.getInt(_lastSyncKey) ?? 0;
  }

  // Chat Data Caching
  static Future<void> saveChatRooms(String chatRoomsJson) async {
    await _prefs?.setString('cached_chat_rooms', chatRoomsJson);
  }

  static String? getCachedChatRooms() {
    return _prefs?.getString('cached_chat_rooms');
  }

  static Future<void> saveMessages(
      String chatRoomId, String messagesJson) async {
    await _prefs?.setString('cached_messages_$chatRoomId', messagesJson);
  }

  static String? getCachedMessages(String chatRoomId) {
    return _prefs?.getString('cached_messages_$chatRoomId');
  }

  static Future<void> clearCachedMessages(String chatRoomId) async {
    await _prefs?.remove('cached_messages_$chatRoomId');
  }

  static Future<void> clearAllCachedData() async {
    final keys =
        _prefs?.getKeys().where((key) => key.startsWith('cached_')).toList() ??
            [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }

  // Utility Methods
  static Future<bool> hasAuthTokens() async {
    final token = await getAuthToken();
    final refreshToken = await getRefreshToken();
    return token != null && refreshToken != null;
  }

  static Future<void> clearAllData() async {
    await Future.wait([
      clearAuthTokens(),
      clearAllCachedData(),
      _prefs?.clear() ?? Future.value(),
    ]);
  }

  // Draft Message Management
  static Future<void> saveDraftMessage(
      String chatRoomId, String message) async {
    await _prefs?.setString('draft_$chatRoomId', message);
  }

  static String? getDraftMessage(String chatRoomId) {
    return _prefs?.getString('draft_$chatRoomId');
  }

  static Future<void> clearDraftMessage(String chatRoomId) async {
    await _prefs?.remove('draft_$chatRoomId');
  }

  // App State Management
  static Future<void> setAppLaunchCount(int count) async {
    await _prefs?.setInt('app_launch_count', count);
  }

  static int getAppLaunchCount() {
    return _prefs?.getInt('app_launch_count') ?? 0;
  }

  static Future<void> setFirstLaunch(bool isFirst) async {
    await _prefs?.setBool('first_launch', isFirst);
  }

  static bool isFirstLaunch() {
    return _prefs?.getBool('first_launch') ?? true;
  }

  // Debug Methods
  static Future<Map<String, String>> getAllSecureStorageData() async {
    return await _secureStorage.readAll();
  }

  static Map<String, dynamic>? getAllPreferencesData() {
    final keys = _prefs?.getKeys() ?? <String>{};
    final Map<String, dynamic> data = {};

    for (final key in keys) {
      final value = _prefs?.get(key);
      data[key] = value;
    }

    return data.isEmpty ? null : data;
  }

  static Future<void> _writeSecureValue(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      // Fall back to shared preferences for environments where secure storage
      // is unavailable or restricted.
    }
  }

  static Future<void> _deleteSecureValue(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Ignore secure storage cleanup failures and remove fallback values.
    }
  }

  static Future<String?> _readAuthValue(String key) async {
    try {
      final secureValue = await _secureStorage.read(key: key);
      if (secureValue != null && secureValue.isNotEmpty) {
        return secureValue;
      }
    } catch (_) {
      // Ignore and fall back to shared preferences.
    }

    final fallbackValue = _prefs?.getString(key);
    if (fallbackValue == null || fallbackValue.isEmpty) {
      return null;
    }

    return fallbackValue;
  }
}
