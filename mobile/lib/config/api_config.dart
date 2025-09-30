class ApiConfig {
  // Base URLs - Update these for production
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'ws://localhost:3000';
  
  // API Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String chatrooms = '/chatrooms';
  
  // Authentication endpoints
  static const String register = '$auth/register';
  static const String login = '$auth/login';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh-token';
  static const String me = '$auth/me';
  static const String resetPassword = '$auth/reset-password';
  
  // User endpoints
  static const String searchUsers = '$users/search';
  static const String onlineUsers = '$users/online';
  static const String updateStatus = '$users/status';
  
  // Chat room endpoints
  static const String createChatRoom = chatrooms;
  static const String getUserChatRooms = chatrooms;
  
  // Helper methods
  static String getChatRoom(String roomId) => '$chatrooms/$roomId';
  static String joinChatRoom(String roomId) => '$chatrooms/$roomId/join';
  static String leaveChatRoom(String roomId) => '$chatrooms/$roomId/leave';
  static String getChatMessages(String roomId) => '$chatrooms/$roomId/messages';
  static String sendMessage(String roomId) => '$chatrooms/$roomId/messages';
  static String markAsRead(String roomId) => '$chatrooms/$roomId/read';
  static String getUnreadCount(String roomId) => '$chatrooms/$roomId/unread-count';
  static String editMessage(String messageId) => '$chatrooms/messages/$messageId';
  static String deleteMessage(String messageId) => '$chatrooms/messages/$messageId';
  static String getUserById(String userId) => '$users/$userId';
  
  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File upload limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedFileTypes = ['pdf', 'doc', 'docx', 'txt', 'zip'];
}