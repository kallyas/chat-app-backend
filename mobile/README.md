# Chat App Mobile

A modern Flutter mobile application for real-time chat communication.

## Features

### 🔐 Authentication
- **Login/Register**: Secure user authentication with email validation
- **JWT Token Management**: Automatic token refresh and secure storage
- **Password Reset**: Email-based password recovery
- **Auto-login**: Seamless app restart experience

### 💬 Real-time Messaging
- **Socket.IO Integration**: Real-time message delivery
- **Typing Indicators**: See when users are typing
- **Read Receipts**: Know when messages are read
- **Online Status**: See who's online/offline

### 👥 Chat Features
- **Private Chats**: One-on-one conversations
- **Group Chats**: Chat with multiple people
- **Message Pagination**: Load older messages with infinite scroll
- **User Search**: Find and connect with other users
- **Message History**: Persistent chat history

### 🎨 Modern UI/UX
- **Material Design 3**: Modern, intuitive interface
- **Dark/Light Theme**: Automatic or manual theme switching
- **Smooth Animations**: Polished user experience
- **Responsive Design**: Works on all screen sizes

### 🔧 Technical Features
- **Provider State Management**: Efficient state handling
- **Secure Storage**: JWT tokens and sensitive data protection
- **Offline Support**: Basic offline functionality
- **Error Handling**: User-friendly error messages
- **Input Validation**: Comprehensive form validation

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code
- iOS/Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kallyas/chat-app-backend.git
   cd chat-app-backend/mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoints**
   - Edit `lib/config/api_config.dart`
   - Update `baseUrl` and `socketUrl` to point to your backend server

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/                   # Configuration files
│   │   ├── api_config.dart       # API endpoints and settings
│   │   └── socket_config.dart    # Socket.IO configuration
│   ├── models/                   # Data models
│   │   ├── user.dart            # User model
│   │   ├── chat_room.dart       # Chat room model
│   │   ├── message.dart         # Message model
│   │   └── api_response.dart    # API response wrapper
│   ├── services/                # Business logic services
│   │   ├── api_service.dart     # HTTP client with interceptors
│   │   ├── auth_service.dart    # Authentication service
│   │   ├── chat_service.dart    # Chat operations service
│   │   ├── socket_service.dart  # Real-time communication
│   │   └── storage_service.dart # Local storage management
│   ├── providers/               # State management
│   │   ├── auth_provider.dart   # Authentication state
│   │   ├── chat_provider.dart   # Chat state and real-time events
│   │   └── theme_provider.dart  # Theme and UI state
│   ├── screens/                 # UI screens
│   │   ├── auth/               # Authentication screens
│   │   ├── home/               # Main app screens
│   │   ├── chat/               # Chat-related screens
│   │   └── settings/           # Settings screens
│   ├── widgets/                # Reusable UI components
│   └── utils/                  # Utilities and helpers
│       ├── constants.dart      # App constants
│       ├── validators.dart     # Form validation
│       └── formatters.dart     # Data formatting
├── assets/                     # Static assets
│   ├── images/                # Image assets
│   └── icons/                 # Icon assets
└── pubspec.yaml               # Dependencies and configuration
```

## Key Dependencies

- **provider**: State management
- **dio**: HTTP client with interceptors
- **socket_io_client**: Real-time communication
- **flutter_secure_storage**: Secure token storage
- **shared_preferences**: User preferences
- **cached_network_image**: Image caching
- **intl**: Internationalization and formatting

## Configuration

### API Configuration

Update `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://your-server.com/api';
  static const String socketUrl = 'http://your-server.com';
  // ... other configurations
}
```

### App Branding

- **App ID**: `com.iden.chat`
- **App Name**: Chat App
- **Organization**: com.iden

## State Management

The app uses the Provider pattern for state management with three main providers:

### AuthProvider
- User authentication state
- Login/logout functionality
- Profile management
- Token handling

### ChatProvider
- Chat rooms and messages
- Real-time event handling
- User search and management
- Socket.IO integration

### ThemeProvider
- Dark/light theme switching
- UI customization
- Color schemes

## Real-time Features

### Socket.IO Events

**Client to Server:**
- `joinRoom` - Join a chat room
- `leaveRoom` - Leave a chat room
- `sendMessage` - Send a message
- `typing` - Start typing indicator
- `stopTyping` - Stop typing indicator

**Server to Client:**
- `newMessage` - New message received
- `userTyping` - User typing status
- `userJoined` - User joined room
- `userLeft` - User left room
- `messageRead` - Message read receipt

## Security

- **JWT Authentication**: Secure token-based authentication
- **Automatic Token Refresh**: Seamless token renewal
- **Secure Storage**: Encrypted storage for sensitive data
- **Input Validation**: Client-side validation for all forms
- **Error Handling**: Secure error messages without data leakage

## Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Backend Integration

This mobile app is designed to work with the Node.js/Express backend in the same repository. Make sure to:

1. Start the backend server
2. Update API endpoints in the mobile configuration
3. Ensure proper CORS configuration on the backend

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Check API endpoint configuration
   - Verify backend server is running
   - Check network connectivity

2. **Build Issues**
   - Run `flutter clean && flutter pub get`
   - Update Flutter SDK if needed
   - Check platform-specific requirements

3. **Socket.IO Issues**
   - Verify Socket.IO server is running
   - Check WebSocket support on the network
   - Review Socket.IO configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Check the documentation
- Review the backend API documentation