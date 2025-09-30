import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'api_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _apiService = ApiService();

  // User-related methods
  Future<ApiResponse<PaginatedResponse<User>>> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get<PaginatedResponse<User>>(
        ApiConfig.searchUsers,
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
        },
        fromJson: (json) => PaginatedResponse.fromJson(
          json,
          (item) => User.fromJson(item),
          'users',
        ),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to search users: ${e.toString()}',
        code: 'SEARCH_USERS_ERROR',
      );
    }
  }

  Future<ApiResponse<List<User>>> getOnlineUsers() async {
    try {
      final response = await _apiService.get<List<User>>(
        ApiConfig.onlineUsers,
        fromJson: (json) => (json['users'] as List<dynamic>)
            .map((user) => User.fromJson(user))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get online users: ${e.toString()}',
        code: 'GET_ONLINE_USERS_ERROR',
      );
    }
  }

  Future<ApiResponse<User>> getUserById(String userId) async {
    try {
      final response = await _apiService.get<User>(
        ApiConfig.getUserById(userId),
        fromJson: (json) => User.fromJson(json['user']),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get user: ${e.toString()}',
        code: 'GET_USER_ERROR',
      );
    }
  }

  Future<ApiResponse<void>> updateUserStatus({required bool isOnline}) async {
    try {
      final response = await _apiService.put<void>(
        ApiConfig.updateStatus,
        data: {'isOnline': isOnline},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to update status: ${e.toString()}',
        code: 'UPDATE_STATUS_ERROR',
      );
    }
  }

  // Chat room methods
  Future<ApiResponse<ChatRoom>> createChatRoom({
    required String type,
    required List<String> participants,
    String? name,
    String? description,
    String? avatar,
  }) async {
    try {
      final data = {
        'type': type,
        'participants': participants,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (avatar != null) 'avatar': avatar,
      };

      final response = await _apiService.post<ChatRoom>(
        ApiConfig.createChatRoom,
        data: data,
        fromJson: (json) => ChatRoom.fromJson(json['chatRoom']),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to create chat room: ${e.toString()}',
        code: 'CREATE_CHAT_ROOM_ERROR',
      );
    }
  }

  Future<ApiResponse<PaginatedResponse<ChatRoom>>> getUserChatRooms({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get<PaginatedResponse<ChatRoom>>(
        ApiConfig.getUserChatRooms,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        fromJson: (json) => PaginatedResponse.fromJson(
          json,
          (item) => ChatRoom.fromJson(item),
          'chatRooms',
        ),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get chat rooms: ${e.toString()}',
        code: 'GET_CHAT_ROOMS_ERROR',
      );
    }
  }

  Future<ApiResponse<ChatRoom>> getChatRoom(String roomId) async {
    try {
      final response = await _apiService.get<ChatRoom>(
        ApiConfig.getChatRoom(roomId),
        fromJson: (json) => ChatRoom.fromJson(json['chatRoom']),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get chat room: ${e.toString()}',
        code: 'GET_CHAT_ROOM_ERROR',
      );
    }
  }

  Future<ApiResponse<void>> joinChatRoom(String roomId) async {
    try {
      final response = await _apiService.post<void>(
        ApiConfig.joinChatRoom(roomId),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to join chat room: ${e.toString()}',
        code: 'JOIN_CHAT_ROOM_ERROR',
      );
    }
  }

  Future<ApiResponse<void>> leaveChatRoom(String roomId) async {
    try {
      final response = await _apiService.post<void>(
        ApiConfig.leaveChatRoom(roomId),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to leave chat room: ${e.toString()}',
        code: 'LEAVE_CHAT_ROOM_ERROR',
      );
    }
  }

  Future<ApiResponse<int>> getUnreadCount(String roomId) async {
    try {
      final response = await _apiService.get<int>(
        ApiConfig.getUnreadCount(roomId),
        fromJson: (json) => json['unreadCount'] as int,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get unread count: ${e.toString()}',
        code: 'GET_UNREAD_COUNT_ERROR',
      );
    }
  }

  Future<ApiResponse<void>> markMessagesAsRead(String roomId) async {
    try {
      final response = await _apiService.post<void>(
        ApiConfig.markAsRead(roomId),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to mark messages as read: ${e.toString()}',
        code: 'MARK_AS_READ_ERROR',
      );
    }
  }

  // Message methods
  Future<ApiResponse<Message>> sendMessage({
    required String roomId,
    required String content,
    required String type,
    String? replyTo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = {
        'content': content,
        'type': type,
        if (replyTo != null) 'replyTo': replyTo,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _apiService.post<Message>(
        ApiConfig.sendMessage(roomId),
        data: data,
        fromJson: (json) => Message.fromJson(json['message']),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to send message: ${e.toString()}',
        code: 'SEND_MESSAGE_ERROR',
      );
    }
  }

  Future<ApiResponse<PaginatedResponse<Message>>> getMessages({
    required String roomId,
    int page = 1,
    int limit = 20,
    String? before,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (before != null) 'before': before,
      };

      final response = await _apiService.get<PaginatedResponse<Message>>(
        ApiConfig.getChatMessages(roomId),
        queryParameters: queryParams,
        fromJson: (json) => PaginatedResponse.fromJson(
          json,
          (item) => Message.fromJson(item),
          'messages',
        ),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get messages: ${e.toString()}',
        code: 'GET_MESSAGES_ERROR',
      );
    }
  }

  Future<ApiResponse<Message>> editMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await _apiService.put<Message>(
        ApiConfig.editMessage(messageId),
        data: {'content': content},
        fromJson: (json) => Message.fromJson(json['message']),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to edit message: ${e.toString()}',
        code: 'EDIT_MESSAGE_ERROR',
      );
    }
  }

  Future<ApiResponse<void>> deleteMessage(String messageId) async {
    try {
      final response = await _apiService.delete<void>(
        ApiConfig.deleteMessage(messageId),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to delete message: ${e.toString()}',
        code: 'DELETE_MESSAGE_ERROR',
      );
    }
  }

  // File upload methods
  Future<ApiResponse<String>> uploadFile({
    required String filePath,
    required String roomId,
    String? fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Note: This endpoint might need to be adjusted based on your backend implementation
      final response = await _apiService.uploadFile<String>(
        '${ApiConfig.sendMessage(roomId)}/upload',
        filePath,
        additionalData: {
          if (fileName != null) 'fileName': fileName,
        },
        fromJson: (json) => json['fileUrl'] as String,
        onProgress: onProgress,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to upload file: ${e.toString()}',
        code: 'UPLOAD_FILE_ERROR',
      );
    }
  }

  Future<ApiResponse<String>> downloadFile({
    required String fileUrl,
    required String savePath,
    Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _apiService.downloadFile(
        fileUrl,
        savePath,
        onProgress: onProgress,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to download file: ${e.toString()}',
        code: 'DOWNLOAD_FILE_ERROR',
      );
    }
  }

  // Helper methods for chat room management
  Future<ApiResponse<ChatRoom>> createPrivateChat(String otherUserId) async {
    return createChatRoom(
      type: 'private',
      participants: [otherUserId],
    );
  }

  Future<ApiResponse<ChatRoom>> createGroupChat({
    required String name,
    required List<String> participants,
    String? description,
    String? avatar,
  }) async {
    return createChatRoom(
      type: 'group',
      participants: participants,
      name: name,
      description: description,
      avatar: avatar,
    );
  }

  // Pagination helper for infinite scroll
  Future<ApiResponse<List<Message>>> loadMoreMessages({
    required String roomId,
    required String beforeMessageId,
    int limit = 20,
  }) async {
    try {
      final response = await getMessages(
        roomId: roomId,
        page: 1,
        limit: limit,
        before: beforeMessageId,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          message: response.message,
          data: response.data!.items,
        );
      }

      return ApiResponse.error(
        message: response.message,
        code: response.code,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to load more messages: ${e.toString()}',
        code: 'LOAD_MORE_MESSAGES_ERROR',
      );
    }
  }

  // Search messages in a chat room
  Future<ApiResponse<List<Message>>> searchMessages({
    required String roomId,
    required String query,
    int limit = 20,
  }) async {
    try {
      // Note: This endpoint might need to be implemented in the backend
      final response = await _apiService.get<List<Message>>(
        '${ApiConfig.getChatMessages(roomId)}/search',
        queryParameters: {
          'q': query,
          'limit': limit,
        },
        fromJson: (json) => (json['messages'] as List<dynamic>)
            .map((msg) => Message.fromJson(msg))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to search messages: ${e.toString()}',
        code: 'SEARCH_MESSAGES_ERROR',
      );
    }
  }
}