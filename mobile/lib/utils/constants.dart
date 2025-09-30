import 'package:flutter/material.dart';

// App constants
class AppConstants {
  // App info
  static const String appName = 'Chat App';
  static const String appVersion = '1.0.0';
  static const String organizationName = 'com.iden.chat';

  // API constants
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Socket constants
  static const Duration socketTimeout = Duration(seconds: 20);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;

  // Typing indicator
  static const Duration typingTimeout = Duration(seconds: 3);
  static const Duration typingDebounce = Duration(milliseconds: 500);

  // File upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedFileTypes = ['pdf', 'doc', 'docx', 'txt', 'zip'];

  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Message constraints
  static const int maxMessageLength = 2000;
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;
  static const int minPasswordLength = 6;

  // Chat room constraints
  static const int maxChatRoomNameLength = 50;
  static const int maxChatRoomDescriptionLength = 200;
  static const int maxGroupParticipants = 100;

  // Pagination
  static const int messagesPerPage = 20;
  static const int chatRoomsPerPage = 20;
  static const int usersPerPage = 20;

  // Cache durations
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration userStatusCacheExpiration = Duration(minutes: 5);
  static const Duration messageCacheExpiration = Duration(hours: 1);

  // Notification settings
  static const String notificationChannelId = 'chat_notifications';
  static const String notificationChannelName = 'Chat Notifications';
  static const String notificationChannelDescription = 'Receive notifications for new messages';

  // Shared preference keys
  static const String themeModeKey = 'theme_mode';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String soundEnabledKey = 'sound_enabled';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String firstLaunchKey = 'first_launch';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unauthorizedErrorMessage = 'Unauthorized access. Please login again.';
  static const String timeoutErrorMessage = 'Request timeout. Please try again.';
  static const String unknownErrorMessage = 'An unexpected error occurred.';

  // Success messages
  static const String loginSuccessMessage = 'Welcome back!';
  static const String registerSuccessMessage = 'Account created successfully!';
  static const String logoutSuccessMessage = 'Logged out successfully';
  static const String passwordResetRequestSuccessMessage = 'Password reset email sent';
  static const String passwordResetSuccessMessage = 'Password reset successfully';
  static const String profileUpdateSuccessMessage = 'Profile updated successfully';

  // Input validation messages
  static const String emailRequiredMessage = 'Email is required';
  static const String emailInvalidMessage = 'Please enter a valid email';
  static const String passwordRequiredMessage = 'Password is required';
  static const String passwordTooShortMessage = 'Password must be at least 6 characters';
  static const String usernameRequiredMessage = 'Username is required';
  static const String usernameInvalidMessage = 'Username must be 3-30 characters with only letters, numbers, _ and -';
  static const String passwordMismatchMessage = 'Passwords do not match';
  static const String messageRequiredMessage = 'Message cannot be empty';
  static const String messageTooLongMessage = 'Message is too long (max 2000 characters)';

  // Chat room types
  static const String privateRoomType = 'private';
  static const String groupRoomType = 'group';

  // Message types
  static const String textMessageType = 'text';
  static const String imageMessageType = 'image';
  static const String fileMessageType = 'file';

  // Message status
  static const String sentMessageStatus = 'sent';
  static const String deliveredMessageStatus = 'delivered';
  static const String readMessageStatus = 'read';

  // User status
  static const String onlineStatus = 'online';
  static const String offlineStatus = 'offline';
  static const String awayStatus = 'away';

  // File size formatting
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  // Color constants
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);

  // Asset paths
  static const String logoPath = 'assets/images/logo.png';
  static const String avatarPlaceholderPath = 'assets/images/avatar_placeholder.png';
  static const String chatBackgroundPath = 'assets/images/chat_background.png';

  // Icon paths
  static const String appIconPath = 'assets/icons/app_icon.png';
  static const String notificationIconPath = 'assets/icons/notification_icon.png';

  // Regular expressions
  static final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_-]{3,30}$');
  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final RegExp urlRegex = RegExp(r'https?://(?:[-\w.])+(?:\:[0-9]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:\#(?:[\w.])*)?)?');

  // Date formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String chatTimeFormat = 'HH:mm';
  static const String chatDateFormat = 'MMM dd';

  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Grid layout
  static const int mobileGridColumns = 1;
  static const int tabletGridColumns = 2;
  static const int desktopGridColumns = 3;

  // App lifecycle states
  static const String appStateResumed = 'resumed';
  static const String appStatePaused = 'paused';
  static const String appStateInactive = 'inactive';
  static const String appStateDetached = 'detached';
}

// Storage keys
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String soundEnabled = 'sound_enabled';
  static const String vibrationEnabled = 'vibration_enabled';
  static const String lastSync = 'last_sync_timestamp';
  static const String cachedChatRooms = 'cached_chat_rooms';
  static const String firstLaunch = 'first_launch';
  static const String appLaunchCount = 'app_launch_count';
  
  static String cachedMessages(String chatRoomId) => 'cached_messages_$chatRoomId';
  static String draftMessage(String chatRoomId) => 'draft_$chatRoomId';
}

// Socket events
class SocketEvents {
  // Client to server
  static const String joinRoom = 'joinRoom';
  static const String leaveRoom = 'leaveRoom';
  static const String sendMessage = 'sendMessage';
  static const String typing = 'typing';
  static const String stopTyping = 'stopTyping';
  static const String messageRead = 'messageRead';
  static const String updateStatus = 'updateStatus';

  // Server to client
  static const String connected = 'connected';
  static const String roomJoined = 'roomJoined';
  static const String userJoined = 'userJoined';
  static const String userLeft = 'userLeft';
  static const String newMessage = 'newMessage';
  static const String userTyping = 'userTyping';
  static const String messageReadEvent = 'messageRead';
  static const String userStatusChanged = 'userStatusChanged';
  static const String error = 'error';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';
}

// API endpoints
class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';
  static const String resetPassword = '/auth/reset-password';

  // Users
  static const String searchUsers = '/users/search';
  static const String onlineUsers = '/users/online';
  static const String updateStatus = '/users/status';

  // Chat rooms
  static const String chatrooms = '/chatrooms';
  
  static String getChatRoom(String roomId) => '/chatrooms/$roomId';
  static String joinChatRoom(String roomId) => '/chatrooms/$roomId/join';
  static String leaveChatRoom(String roomId) => '/chatrooms/$roomId/leave';
  static String getChatMessages(String roomId) => '/chatrooms/$roomId/messages';
  static String sendMessage(String roomId) => '/chatrooms/$roomId/messages';
  static String markAsRead(String roomId) => '/chatrooms/$roomId/read';
  static String getUnreadCount(String roomId) => '/chatrooms/$roomId/unread-count';
  static String editMessage(String messageId) => '/chatrooms/messages/$messageId';
  static String deleteMessage(String messageId) => '/chatrooms/messages/$messageId';
  static String getUserById(String userId) => '/users/$userId';
}