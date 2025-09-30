import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_config.dart';

class SocketConfig {
  // Socket.IO configuration options
  static Map<String, dynamic> get options => {
    'transports': ['websocket'],
    'autoConnect': false,
    'timeout': 20000,
    'forceNew': true,
  };
  
  // Create socket instance with authentication
  static IO.Socket createSocket(String token) {
    return IO.io(ApiConfig.socketUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setExtraHeaders({'authorization': 'Bearer $token'})
        .build()
    );
  }
  
  // Socket events - Client to Server
  static const String joinRoom = 'joinRoom';
  static const String leaveRoom = 'leaveRoom';
  static const String sendMessage = 'sendMessage';
  static const String typing = 'typing';
  static const String stopTyping = 'stopTyping';
  static const String messageRead = 'messageRead';
  static const String updateStatus = 'updateStatus';
  
  // Socket events - Server to Client
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
  
  // Connection timeouts
  static const Duration connectionTimeout = Duration(seconds: 20);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;
  
  // Typing indicator settings
  static const Duration typingTimeout = Duration(seconds: 3);
  static const Duration typingDebounce = Duration(milliseconds: 500);
}