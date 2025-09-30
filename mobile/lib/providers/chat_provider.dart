import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

enum ChatState {
  initial,
  loading,
  loaded,
  error,
}

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();

  // State management
  ChatState _state = ChatState.initial;
  String? _errorMessage;
  bool _isLoading = false;

  // Chat data
  List<ChatRoom> _chatRooms = [];
  Map<String, List<Message>> _messages = {};
  Map<String, bool> _isLoadingMessages = {};
  Map<String, bool> _hasMoreMessages = {};
  Map<String, List<String>> _typingUsers = {};
  
  // Chat rooms pagination
  bool _isLoadingChatRooms = false;
  bool _hasMoreChatRooms = true;
  int _currentChatRoomsPage = 1;
  
  // Current chat
  String? _currentChatRoomId;
  ChatRoom? _currentChatRoom;
  
  // Users data
  List<User> _onlineUsers = [];
  Map<String, User> _users = {};

  // Getters
  ChatState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  List<ChatRoom> get chatRooms => _chatRooms;
  String? get currentChatRoomId => _currentChatRoomId;
  ChatRoom? get currentChatRoom => _currentChatRoom;
  List<User> get onlineUsers => _onlineUsers;
  bool get isLoadingChatRooms => _isLoadingChatRooms;
  bool get hasMoreChatRooms => _hasMoreChatRooms;

  List<Message> getMessages(String chatRoomId) {
    return _messages[chatRoomId] ?? [];
  }

  bool isLoadingMessages(String chatRoomId) {
    return _isLoadingMessages[chatRoomId] ?? false;
  }

  bool hasMoreMessages(String chatRoomId) {
    return _hasMoreMessages[chatRoomId] ?? true;
  }

  List<String> getTypingUsers(String chatRoomId) {
    return _typingUsers[chatRoomId] ?? [];
  }

  User? getUser(String userId) {
    return _users[userId];
  }

  // Initialize chat provider
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // Only initialize if we have valid auth tokens
      final hasTokens = await _hasValidAuth();
      if (!hasTokens) {
        _setError('Authentication required');
        return;
      }
      
      // Setup socket listeners
      _setupSocketListeners();
      
      // Connect to socket
      await _socketService.connect();
      
      // Load initial data
      await Future.wait([
        loadChatRooms(),
        loadOnlineUsers(),
      ]);
      
      _setState(ChatState.loaded);
    } catch (e) {
      _setError('Failed to initialize chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Setup socket event listeners
  void _setupSocketListeners() {
    _socketService.setOnNewMessage(_handleNewMessage);
    _socketService.setOnUserJoined(_handleUserJoined);
    _socketService.setOnUserLeft(_handleUserLeft);
    _socketService.setOnUserTyping(_handleUserTyping);
    _socketService.setOnMessageRead(_handleMessageRead);
    _socketService.setOnUserStatusChanged(_handleUserStatusChanged);
    _socketService.setOnError(_handleSocketError);
    _socketService.setOnConnected(_handleSocketConnected);
    _socketService.setOnDisconnected(_handleSocketDisconnected);
  }

  // Load chat rooms
  Future<void> loadChatRooms({bool refresh = false}) async {
    if (_isLoadingChatRooms) return;

    _isLoadingChatRooms = true;
    notifyListeners();

    try {
      final page = refresh ? 1 : (_chatRooms.isEmpty ? 1 : _currentChatRoomsPage + 1);
      final response = await _chatService.getUserChatRooms(page: page);
      
      if (response.success && response.data != null) {
        final newRooms = response.data!.items;
        
        if (refresh) {
          _chatRooms = newRooms;
          _currentChatRoomsPage = 1;
        } else if (_chatRooms.isEmpty) {
          _chatRooms = newRooms;
          _currentChatRoomsPage = 1;
        } else {
          _chatRooms.addAll(newRooms);
          _currentChatRoomsPage++;
        }
        
        _hasMoreChatRooms = response.data!.pagination.hasNext;
        
        // Cache users from chat rooms
        for (final room in _chatRooms) {
          for (final user in room.participants) {
            _users[user.id] = user;
          }
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Failed to load chat rooms: $e');
    } finally {
      _isLoadingChatRooms = false;
      notifyListeners();
    }
  }

  // Load more chat rooms (for infinite scroll)
  Future<void> loadMoreChatRooms() async {
    if (_isLoadingChatRooms || !_hasMoreChatRooms) return;
    
    await loadChatRooms();
  }

  // Load messages for a chat room
  Future<void> loadMessages(String chatRoomId, {bool refresh = false}) async {
    if (_isLoadingMessages[chatRoomId] == true) return;
    
    _isLoadingMessages[chatRoomId] = true;
    notifyListeners();

    try {
      final response = await _chatService.getMessages(roomId: chatRoomId);
      
      if (response.success && response.data != null) {
        if (refresh) {
          _messages[chatRoomId] = response.data!.items.reversed.toList();
        } else {
          _messages[chatRoomId] = (_messages[chatRoomId] ?? []) + response.data!.items.reversed.toList();
        }
        
        _hasMoreMessages[chatRoomId] = response.data!.pagination.hasNext;
        
        // Cache users from messages
        for (final message in response.data!.items) {
          if (message.sender != null) {
            _users[message.sender!.id] = message.sender!;
          }
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Failed to load messages: $e');
    } finally {
      _isLoadingMessages[chatRoomId] = false;
      notifyListeners();
    }
  }

  // Load more messages (for infinite scroll)
  Future<void> loadMoreMessages(String chatRoomId) async {
    if (_isLoadingMessages[chatRoomId] == true || _hasMoreMessages[chatRoomId] == false) {
      return;
    }

    final currentMessages = _messages[chatRoomId] ?? [];
    if (currentMessages.isEmpty) return;

    final oldestMessage = currentMessages.first;
    
    try {
      final response = await _chatService.loadMoreMessages(
        roomId: chatRoomId,
        beforeMessageId: oldestMessage.id,
      );
      
      if (response.success && response.data != null) {
        final newMessages = response.data!.reversed.toList();
        _messages[chatRoomId] = newMessages + currentMessages;
        _hasMoreMessages[chatRoomId] = newMessages.length == 20; // Assuming page size is 20
        
        notifyListeners();
      }
    } catch (e) {
      print('Failed to load more messages: $e');
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String chatRoomId,
    required String content,
    String type = 'text',
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Send via socket for real-time delivery
      _socketService.sendMessage(
        roomId: chatRoomId,
        content: content,
        type: type,
        replyTo: replyToId,
        metadata: metadata,
      );

      // Also send via API for persistence
      final response = await _chatService.sendMessage(
        roomId: chatRoomId,
        content: content,
        type: type,
        replyTo: replyToId,
        metadata: metadata,
      );

      if (response.success) {
        // Message will be added via socket event
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  // Create private chat
  Future<ChatRoom?> createPrivateChat(String otherUserId) async {
    try {
      final response = await _chatService.createPrivateChat(otherUserId);
      
      if (response.success && response.data != null) {
        final newRoom = response.data!;
        _chatRooms.insert(0, newRoom);
        notifyListeners();
        return newRoom;
      } else {
        _setError(response.message);
        return null;
      }
    } catch (e) {
      _setError('Failed to create private chat: $e');
      return null;
    }
  }

  // Create group chat
  Future<ChatRoom?> createGroupChat({
    required String name,
    required List<String> participants,
    String? description,
  }) async {
    try {
      final response = await _chatService.createGroupChat(
        name: name,
        participants: participants,
        description: description,
      );
      
      if (response.success && response.data != null) {
        final newRoom = response.data!;
        _chatRooms.insert(0, newRoom);
        notifyListeners();
        return newRoom;
      } else {
        _setError(response.message);
        return null;
      }
    } catch (e) {
      _setError('Failed to create group chat: $e');
      return null;
    }
  }

  // Set current chat room
  void setCurrentChatRoom(String? chatRoomId) {
    if (_currentChatRoomId != chatRoomId) {
      // Leave previous room
      if (_currentChatRoomId != null) {
        _socketService.leaveRoom(_currentChatRoomId!);
      }
      
      _currentChatRoomId = chatRoomId;
      _currentChatRoom = _chatRooms.firstWhere(
        (room) => room.id == chatRoomId,
        orElse: () => _currentChatRoom!,
      );
      
      // Join new room
      if (chatRoomId != null) {
        _socketService.joinRoom(chatRoomId);
        loadMessages(chatRoomId, refresh: true);
        markMessagesAsRead(chatRoomId);
      }
      
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      await _chatService.markMessagesAsRead(chatRoomId);
      
      // Update local chat room unread count
      final roomIndex = _chatRooms.indexWhere((room) => room.id == chatRoomId);
      if (roomIndex != -1) {
        _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  // Start typing
  void startTyping(String chatRoomId) {
    _socketService.startTyping(chatRoomId);
  }

  // Stop typing
  void stopTyping(String chatRoomId) {
    _socketService.stopTyping(chatRoomId);
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _chatService.searchUsers(query: query);
      debugPrint('Search users response: $response');
      
      if (response.success && response.data != null) {
        final users = response.data!.items;
        
        // Cache users
        for (final user in users) {
          _users[user.id] = user;
        }
        
        return users;
      } else {
        _setError(response.message);
        return [];
      }
    } catch (e) {
      _setError('Failed to search users: $e');
      return [];
    }
  }

  // Load online users
  Future<void> loadOnlineUsers() async {
    try {
      final response = await _chatService.getOnlineUsers();
      
      if (response.success && response.data != null) {
        _onlineUsers = response.data!.items;
        
        // Cache users
        for (final user in _onlineUsers) {
          _users[user.id] = user;
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Failed to load online users: $e');
    }
  }

  // Socket event handlers
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data['message']);
      final chatRoomId = message.chatRoomId;
      
      // Add message to list
      _messages[chatRoomId] = (_messages[chatRoomId] ?? [])..add(message);
      
      // Update chat room last message and move to top
      final roomIndex = _chatRooms.indexWhere((room) => room.id == chatRoomId);
      if (roomIndex != -1) {
        final room = _chatRooms[roomIndex];
        final updatedRoom = room.copyWith(
          lastMessage: message,
          updatedAt: message.createdAt,
          unreadCount: chatRoomId != _currentChatRoomId ? room.unreadCount + 1 : 0,
        );
        
        _chatRooms.removeAt(roomIndex);
        _chatRooms.insert(0, updatedRoom);
      }
      
      // Auto-mark as read if in current chat
      if (chatRoomId == _currentChatRoomId) {
        markMessagesAsRead(chatRoomId);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  void _handleUserJoined(Map<String, dynamic> data) {
    // Handle user joined chat room
    notifyListeners();
  }

  void _handleUserLeft(Map<String, dynamic> data) {
    // Handle user left chat room
    notifyListeners();
  }

  void _handleUserTyping(Map<String, dynamic> data) {
    try {
      final userId = data['userId'];
      final chatRoomId = data['roomId'] ?? _currentChatRoomId;
      final isTyping = data['isTyping'] ?? false;
      
      if (chatRoomId != null) {
        final typingList = _typingUsers[chatRoomId] ?? [];
        
        if (isTyping && !typingList.contains(userId)) {
          typingList.add(userId);
        } else if (!isTyping) {
          typingList.remove(userId);
        }
        
        _typingUsers[chatRoomId] = typingList;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling user typing: $e');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    // Handle message read receipt
    notifyListeners();
  }

  void _handleUserStatusChanged(Map<String, dynamic> data) {
    try {
      final userId = data['userId'];
      final status = data['status'];
      
      if (_users.containsKey(userId)) {
        final user = _users[userId]!;
        _users[userId] = user.copyWith(
          isOnline: status == 'online',
          lastSeen: status != 'online' ? DateTime.now() : null,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error handling user status change: $e');
    }
  }

  void _handleSocketError(String error) {
    print('Socket error: $error');
    _setError('Connection error: $error');
  }

  void _handleSocketConnected() {
    print('Socket connected');
    _clearError();
  }

  void _handleSocketDisconnected() {
    print('Socket disconnected');
    // Attempt to reconnect
    Future.delayed(const Duration(seconds: 5), () {
      _socketService.reconnect();
    });
  }

  // Edit message
  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      final response = await _chatService.editMessage(
        messageId: messageId,
        content: newContent,
      );
      
      if (response.success) {
        // Update local message
        for (final messages in _messages.values) {
          final index = messages.indexWhere((msg) => msg.id == messageId);
          if (index != -1) {
            messages[index] = messages[index].copyWith(
              content: newContent,
              edited: true,
              editedAt: DateTime.now(),
            );
            break;
          }
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to edit message: $e');
      return false;
    }
  }

  // Delete message
  Future<bool> deleteMessage(String messageId) async {
    try {
      final response = await _chatService.deleteMessage(messageId);
      
      if (response.success) {
        // Remove from local messages
        for (final messages in _messages.values) {
          messages.removeWhere((msg) => msg.id == messageId);
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete message: $e');
      return false;
    }
  }

  // Get total unread count
  int get totalUnreadCount {
    return _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  // Private helper methods
  void _setState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = ChatState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_state == ChatState.error) {
      _state = ChatState.loaded;
    }
    notifyListeners();
  }

  // Cleanup
  void dispose() {
    _socketService.clearCallbacks();
    _socketService.disconnect();
    super.dispose();
  }

  // Clear all data
  void clear() {
    _chatRooms.clear();
    _messages.clear();
    _isLoadingMessages.clear();
    _hasMoreMessages.clear();
    _typingUsers.clear();
    _currentChatRoomId = null;
    _currentChatRoom = null;
    _onlineUsers.clear();
    _users.clear();
    _isLoadingChatRooms = false;
    _hasMoreChatRooms = true;
    _currentChatRoomsPage = 1;
    _setState(ChatState.initial);
  }

  // Check if we have valid authentication
  Future<bool> _hasValidAuth() async {
    return await StorageService.hasAuthTokens();
  }
}