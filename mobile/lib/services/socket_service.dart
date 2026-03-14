import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'dart:async';
import '../config/socket_config.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  socket_io.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;

  // Typing indicator throttling (max 10 per minute = 1 per 6 seconds)
  DateTime? _lastTypingEvent;
  static const Duration _typingThrottle = Duration(seconds: 1);

  // Event callbacks
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onUserJoined;
  Function(Map<String, dynamic>)? onUserLeft;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(Map<String, dynamic>)? onMessageRead;
  Function(Map<String, dynamic>)? onUserStatusChanged;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  // Initialize socket connection
  Future<void> connect() async {
    try {
      final token = await StorageService.getAuthToken();
      final userId = await StorageService.getUserId();

      if (token == null || userId == null) {
        throw Exception('No authentication token or user ID found');
      }

      _currentUserId = userId;
      _socket = SocketConfig.createSocket(token);

      _setupEventListeners();
      _socket!.connect();

      print('🔌 Connecting to socket...');
    } catch (e) {
      print('❌ Socket connection error: $e');
      onError?.call('Failed to connect: $e');
    }
  }

  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      print('🔌 Socket disconnected');
    }
  }

  // Setup event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.on(SocketConfig.connected, (data) {
      _isConnected = true;
      print('✅ Socket connected: $data');
      onConnected?.call();
    });

    _socket!.on('connect', (data) {
      _isConnected = true;
      print('✅ Socket connected');
      onConnected?.call();
    });

    _socket!.on(SocketConfig.disconnect, (data) {
      _isConnected = false;
      print('❌ Socket disconnected: $data');
      onDisconnected?.call();
    });

    _socket!.on(SocketConfig.connectError, (data) {
      _isConnected = false;
      print('❌ Socket connection error: $data');

      // Check for token invalidation errors
      final errorMessage = data.toString().toLowerCase();
      if (errorMessage.contains('invalidated') ||
          errorMessage.contains('token has been') ||
          errorMessage.contains('authentication failed')) {
        print('⚠️ Socket auth failed - token may be invalidated');
        onError?.call('Your session has expired. Please login again.');
        // Clear tokens and disconnect
        StorageService.clearAuthTokens();
        disconnect();
      } else {
        onError?.call('Connection error: $data');
      }
    });

    // Chat events
    _socket!.on(SocketConfig.newMessage, (data) {
      print('📨 New message received: $data');
      onNewMessage?.call(data);
    });

    _socket!.on(SocketConfig.userJoined, (data) {
      print('👋 User joined: $data');
      onUserJoined?.call(data);
    });

    _socket!.on(SocketConfig.userLeft, (data) {
      print('👋 User left: $data');
      onUserLeft?.call(data);
    });

    _socket!.on(SocketConfig.userTyping, (data) {
      print('⌨️ User typing: $data');
      onUserTyping?.call(data);
    });

    _socket!.on(SocketConfig.messageReadEvent, (data) {
      print('👁️ Message read: $data');
      onMessageRead?.call(data);
    });

    _socket!.on(SocketConfig.userStatusChanged, (data) {
      print('📊 User status changed: $data');
      onUserStatusChanged?.call(data);
    });

    _socket!.on(SocketConfig.error, (data) {
      print('❌ Socket error: $data');

      // Check for rate limiting errors
      final errorMessage = data.toString().toLowerCase();
      if (errorMessage.contains('rate limit')) {
        print('⚠️ Rate limit exceeded');
        onError
            ?.call('You\'re sending messages too quickly. Please slow down.');
      } else if (errorMessage.contains('room not found') ||
          errorMessage.contains('access denied')) {
        onError?.call('Room access denied or not found');
      } else {
        onError?.call(data.toString());
      }
    });
  }

  // Join a chat room
  void joinRoom(String roomId) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected, cannot join room');
      return;
    }

    _socket!.emit(SocketConfig.joinRoom, {
      'roomId': roomId,
    });
    print('🚪 Joining room: $roomId');
  }

  // Leave a chat room
  void leaveRoom(String roomId) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected, cannot leave room');
      return;
    }

    _socket!.emit(SocketConfig.leaveRoom, {
      'roomId': roomId,
    });
    print('🚪 Leaving room: $roomId');
  }

  // Send a message
  Future<ApiResponse<Map<String, dynamic>>> sendMessage({
    required String roomId,
    required String content,
    required String type,
    String? replyTo,
    Map<String, dynamic>? metadata,
  }) async {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected, cannot send message');
      return ApiResponse.error(
        message: 'Socket not connected',
        code: 'SOCKET_DISCONNECTED',
      );
    }

    final messageData = {
      'roomId': roomId,
      'content': content,
      'type': type,
      if (replyTo != null) 'replyTo': replyTo,
      if (metadata != null) 'metadata': metadata,
    };

    print('📤 Sending message: $messageData');

    try {
      final completer = Completer<dynamic>();

      _socket!.emitWithAck(
        SocketConfig.sendMessage,
        messageData,
        ack: (dynamic ack) {
          if (!completer.isCompleted) {
            completer.complete(ack);
          }
        },
      );

      final ack = await completer.future.timeout(const Duration(seconds: 10));

      if (ack is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          ack,
          (json) => json as Map<String, dynamic>,
        );
      }

      return ApiResponse.error(
        message: 'Unexpected socket response',
        code: 'INVALID_SOCKET_ACK',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to send message: $e',
        code: 'SOCKET_SEND_ERROR',
      );
    }
  }

  // Send typing indicator (throttled to max 10/min = 1 per 6 seconds)
  void startTyping(String roomId) {
    if (_socket == null || !_isConnected) return;

    // Throttle typing events to prevent rate limiting
    final now = DateTime.now();
    if (_lastTypingEvent != null &&
        now.difference(_lastTypingEvent!) < _typingThrottle) {
      print('⏱️ Typing event throttled - too soon since last event');
      return; // Skip this event
    }

    _lastTypingEvent = now;
    _socket!.emit(SocketConfig.typing, {
      'roomId': roomId,
      'isTyping': true,
    });
  }

  // Stop typing indicator
  void stopTyping(String roomId) {
    if (_socket == null || !_isConnected) return;

    _lastTypingEvent = null;
    _socket!.emit(SocketConfig.stopTyping, {
      'roomId': roomId,
    });
  }

  // Mark message as read
  void markMessageAsRead({
    required String roomId,
    required String messageId,
  }) {
    if (_socket == null || !_isConnected) return;

    _socket!.emit(SocketConfig.messageRead, {
      'roomId': roomId,
      'messageId': messageId,
    });
  }

  // Update user status
  void updateStatus(String status) {
    if (_socket == null || !_isConnected) return;

    _socket!.emit(SocketConfig.updateStatus, {
      'status': status,
    });
  }

  // Reconnect with exponential backoff
  Future<void> reconnect() async {
    if (_isConnected) return;

    disconnect();

    int attempts = 0;
    const maxAttempts = SocketConfig.maxReconnectAttempts;

    while (attempts < maxAttempts && !_isConnected) {
      attempts++;
      print('🔄 Reconnection attempt $attempts/$maxAttempts');

      try {
        await connect();
        if (_isConnected) {
          print('✅ Reconnected successfully');
          return;
        }
      } catch (e) {
        print('❌ Reconnection attempt $attempts failed: $e');
      }

      if (attempts < maxAttempts) {
        final delay = Duration(
          seconds: SocketConfig.reconnectDelay.inSeconds * attempts,
        );
        await Future.delayed(delay);
      }
    }

    if (!_isConnected) {
      print('❌ Failed to reconnect after $maxAttempts attempts');
      onError?.call('Failed to reconnect to server');
    }
  }

  // Set event listeners
  void setOnNewMessage(Function(Map<String, dynamic>) callback) {
    onNewMessage = callback;
  }

  void setOnUserJoined(Function(Map<String, dynamic>) callback) {
    onUserJoined = callback;
  }

  void setOnUserLeft(Function(Map<String, dynamic>) callback) {
    onUserLeft = callback;
  }

  void setOnUserTyping(Function(Map<String, dynamic>) callback) {
    onUserTyping = callback;
  }

  void setOnMessageRead(Function(Map<String, dynamic>) callback) {
    onMessageRead = callback;
  }

  void setOnUserStatusChanged(Function(Map<String, dynamic>) callback) {
    onUserStatusChanged = callback;
  }

  void setOnError(Function(String) callback) {
    onError = callback;
  }

  void setOnConnected(Function() callback) {
    onConnected = callback;
  }

  void setOnDisconnected(Function() callback) {
    onDisconnected = callback;
  }

  // Clear all callbacks
  void clearCallbacks() {
    onNewMessage = null;
    onUserJoined = null;
    onUserLeft = null;
    onUserTyping = null;
    onMessageRead = null;
    onUserStatusChanged = null;
    onError = null;
    onConnected = null;
    onDisconnected = null;
  }

  // Get current user ID
  String? get currentUserId => _currentUserId;

  // Force disconnect and clear
  void forceDisconnect() {
    clearCallbacks();
    disconnect();
    _currentUserId = null;
  }
}
