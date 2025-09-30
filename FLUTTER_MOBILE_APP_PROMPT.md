# Flutter Chat Mobile App Development Prompt

Create a complete Flutter mobile application for a real-time chat system in the `mobile/` folder. The app should integrate with the existing Node.js/Express backend API and provide a modern, intuitive chat experience.

## Project Requirements

### 1. Project Structure
```
mobile/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   ├── api_config.dart
│   │   └── socket_config.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── chat_room.dart
│   │   ├── message.dart
│   │   └── api_response.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── chat_service.dart
│   │   ├── socket_service.dart
│   │   └── storage_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── chat_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── chat_list_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── chat/
│   │   │   ├── chat_screen.dart
│   │   │   ├── create_chat_screen.dart
│   │   │   └── chat_info_screen.dart
│   │   └── settings/
│   │       └── settings_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   ├── auth/
│   │   ├── chat/
│   │   └── profile/
│   └── utils/
│       ├── constants.dart
│       ├── validators.dart
│       └── formatters.dart
├── assets/
│   ├── images/
│   └── icons/
├── pubspec.yaml
└── README.md
```

### 2. Dependencies
Add these to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  provider: ^6.1.1
  
  # HTTP & API
  http: ^1.1.0
  dio: ^5.3.0
  
  # Real-time Communication
  socket_io_client: ^2.0.3+1
  
  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # UI Components
  cupertino_icons: ^1.0.6
  flutter_spinkit: ^5.2.0
  cached_network_image: ^3.3.0
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.1.0
  
  # Image Handling
  image_picker: ^1.0.4
  
  # Permissions
  permission_handler: ^11.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## Backend API Integration

### Base URL Configuration
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';
  
  // Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String chatrooms = '/chatrooms';
}
```

## API Endpoints Documentation

### Authentication Endpoints

#### 1. Register User
- **POST** `/api/auth/register`
- **Request Body:**
```json
{
  "username": "string (3-30 chars, alphanumeric + _-)",
  "email": "string (valid email)",
  "password": "string (min 6 chars)"
}
```
- **Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "_id": "ObjectId",
      "username": "string",
      "email": "string",
      "profilePic": "string",
      "isOnline": false,
      "lastSeen": "Date",
      "createdAt": "Date",
      "updatedAt": "Date"
    },
    "token": "string",
    "refreshToken": "string"
  }
}
```

#### 2. Login User
- **POST** `/api/auth/login`
- **Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```
- **Response:** Same as register

#### 3. Refresh Token
- **POST** `/api/auth/refresh-token`
- **Request Body:**
```json
{
  "refreshToken": "string"
}
```
- **Response:**
```json
{
  "success": true,
  "data": {
    "token": "string",
    "refreshToken": "string"
  }
}
```

#### 4. Get Current User
- **GET** `/api/auth/me`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "_id": "ObjectId",
      "username": "string",
      "email": "string",
      "profilePic": "string",
      "isOnline": boolean,
      "lastSeen": "Date",
      "createdAt": "Date",
      "updatedAt": "Date"
    }
  }
}
```

#### 5. Update Profile
- **PUT** `/api/auth/me`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "username": "string (optional)",
  "profilePic": "string (optional)"
}
```

#### 6. Logout
- **POST** `/api/auth/logout`
- **Headers:** `Authorization: Bearer <token>`

#### 7. Forgot Password
- **POST** `/api/auth/reset-password`
- **Request Body:**
```json
{
  "email": "string"
}
```

#### 8. Reset Password
- **POST** `/api/auth/reset-password/:token`
- **Request Body:**
```json
{
  "password": "string"
}
```

### User Endpoints

#### 1. Search Users
- **GET** `/api/users/search?q=<query>&limit=<number>&page=<number>`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "_id": "ObjectId",
        "username": "string",
        "email": "string",
        "profilePic": "string",
        "isOnline": boolean,
        "lastSeen": "Date"
      }
    ],
    "pagination": {
      "page": number,
      "limit": number,
      "total": number,
      "totalPages": number
    }
  }
}
```

#### 2. Get Online Users
- **GET** `/api/users/online`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "_id": "ObjectId",
        "username": "string",
        "profilePic": "string",
        "lastSeen": "Date"
      }
    ]
  }
}
```

#### 3. Get User By ID
- **GET** `/api/users/:userId`
- **Headers:** `Authorization: Bearer <token>`

#### 4. Update Online Status
- **PUT** `/api/users/status`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "isOnline": boolean
}
```

### Chat Room Endpoints

#### 1. Create Chat Room
- **POST** `/api/chatrooms`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "type": "private | group",
  "participants": ["ObjectId"],
  "name": "string (required for group)",
  "description": "string (optional)",
  "avatar": "string (optional)"
}
```
- **Response:**
```json
{
  "success": true,
  "data": {
    "chatRoom": {
      "_id": "ObjectId",
      "name": "string",
      "type": "private | group",
      "participants": ["ObjectId"],
      "createdBy": "ObjectId",
      "description": "string",
      "avatar": "string",
      "isActive": true,
      "lastMessage": {
        "content": "string",
        "sender": "ObjectId",
        "timestamp": "Date",
        "messageType": "text | image | file"
      },
      "createdAt": "Date",
      "updatedAt": "Date"
    }
  }
}
```

#### 2. Get User Chat Rooms
- **GET** `/api/chatrooms?page=<number>&limit=<number>`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "chatRooms": [
      {
        "_id": "ObjectId",
        "name": "string",
        "type": "private | group",
        "participants": [
          {
            "_id": "ObjectId",
            "username": "string",
            "profilePic": "string",
            "isOnline": boolean
          }
        ],
        "lastMessage": {
          "content": "string",
          "sender": {
            "_id": "ObjectId",
            "username": "string"
          },
          "timestamp": "Date",
          "messageType": "text | image | file"
        },
        "unreadCount": number,
        "updatedAt": "Date"
      }
    ],
    "pagination": {
      "page": number,
      "limit": number,
      "total": number,
      "totalPages": number
    }
  }
}
```

#### 3. Get Chat Room by ID
- **GET** `/api/chatrooms/:roomId`
- **Headers:** `Authorization: Bearer <token>`

#### 4. Join Chat Room
- **POST** `/api/chatrooms/:roomId/join`
- **Headers:** `Authorization: Bearer <token>`

#### 5. Leave Chat Room
- **POST** `/api/chatrooms/:roomId/leave`
- **Headers:** `Authorization: Bearer <token>`

#### 6. Get Unread Count
- **GET** `/api/chatrooms/:roomId/unread-count`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "unreadCount": number
  }
}
```

#### 7. Mark Messages as Read
- **POST** `/api/chatrooms/:roomId/read`
- **Headers:** `Authorization: Bearer <token>`

### Message Endpoints

#### 1. Send Message
- **POST** `/api/chatrooms/:roomId/messages`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "content": "string (max 2000 chars)",
  "type": "text | image | file",
  "replyTo": "ObjectId (optional)",
  "metadata": {
    "fileName": "string (optional)",
    "fileSize": number,
    "mimeType": "string",
    "imageWidth": number,
    "imageHeight": number
  }
}
```
- **Response:**
```json
{
  "success": true,
  "data": {
    "message": {
      "_id": "ObjectId",
      "chatRoomId": "ObjectId",
      "senderId": "ObjectId",
      "content": "string",
      "type": "text | image | file",
      "status": "sent | delivered | read",
      "readBy": [
        {
          "userId": "ObjectId",
          "readAt": "Date"
        }
      ],
      "edited": false,
      "replyTo": "ObjectId",
      "metadata": {},
      "createdAt": "Date",
      "updatedAt": "Date"
    }
  }
}
```

#### 2. Get Messages
- **GET** `/api/chatrooms/:roomId/messages?page=<number>&limit=<number>&before=<messageId>`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "_id": "ObjectId",
        "chatRoomId": "ObjectId",
        "sender": {
          "_id": "ObjectId",
          "username": "string",
          "profilePic": "string"
        },
        "content": "string",
        "type": "text | image | file",
        "status": "sent | delivered | read",
        "readBy": [
          {
            "userId": "ObjectId",
            "readAt": "Date"
          }
        ],
        "edited": boolean,
        "editedAt": "Date",
        "replyTo": {
          "_id": "ObjectId",
          "content": "string",
          "sender": {
            "username": "string"
          }
        },
        "metadata": {},
        "createdAt": "Date"
      }
    ],
    "pagination": {
      "page": number,
      "limit": number,
      "hasMore": boolean
    }
  }
}
```

#### 3. Edit Message
- **PUT** `/api/chatrooms/messages/:messageId`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "content": "string"
}
```

#### 4. Delete Message
- **DELETE** `/api/chatrooms/messages/:messageId`
- **Headers:** `Authorization: Bearer <token>`

#### 5. Mark Message as Read
- **POST** `/api/chatrooms/messages/:messageId/read`
- **Headers:** `Authorization: Bearer <token>`

## WebSocket Events

### Client to Server Events

#### 1. Join Room
```json
{
  "event": "joinRoom",
  "data": {
    "roomId": "string"
  }
}
```

#### 2. Leave Room
```json
{
  "event": "leaveRoom", 
  "data": {
    "roomId": "string"
  }
}
```

#### 3. Send Message
```json
{
  "event": "sendMessage",
  "data": {
    "roomId": "string",
    "content": "string",
    "type": "text | image | file",
    "replyTo": "string (optional)",
    "metadata": {}
  }
}
```

#### 4. Typing Indicator
```json
{
  "event": "typing",
  "data": {
    "roomId": "string",
    "isTyping": boolean
  }
}
```

#### 5. Stop Typing
```json
{
  "event": "stopTyping",
  "data": {
    "roomId": "string"
  }
}
```

#### 6. Message Read
```json
{
  "event": "messageRead",
  "data": {
    "roomId": "string",
    "messageId": "string"
  }
}
```

#### 7. Update Status
```json
{
  "event": "updateStatus",
  "data": {
    "status": "online | offline | away"
  }
}
```

### Server to Client Events

#### 1. Room Joined
```json
{
  "event": "roomJoined",
  "data": {
    "roomId": "string",
    "message": "string"
  }
}
```

#### 2. User Joined
```json
{
  "event": "userJoined",
  "data": {
    "userId": "string",
    "username": "string",
    "timestamp": "Date"
  }
}
```

#### 3. User Left
```json
{
  "event": "userLeft",
  "data": {
    "userId": "string",
    "username": "string", 
    "timestamp": "Date"
  }
}
```

#### 4. New Message
```json
{
  "event": "newMessage",
  "data": {
    "message": {
      "_id": "string",
      "chatRoomId": "string",
      "senderId": "string",
      "content": "string",
      "type": "text | image | file",
      "createdAt": "Date"
    },
    "timestamp": "Date"
  }
}
```

#### 5. User Typing
```json
{
  "event": "userTyping",
  "data": {
    "userId": "string",
    "username": "string",
    "isTyping": boolean,
    "timestamp": "Date"
  }
}
```

#### 6. Message Read
```json
{
  "event": "messageRead",
  "data": {
    "messageId": "string",
    "userId": "string",
    "username": "string",
    "readAt": "Date"
  }
}
```

#### 7. User Status Changed
```json
{
  "event": "userStatusChanged",
  "data": {
    "userId": "string",
    "username": "string",
    "status": "online | offline | away",
    "timestamp": "Date"
  }
}
```

#### 8. Error
```json
{
  "event": "error",
  "data": {
    "message": "string"
  }
}
```

## Key Features to Implement

### 1. Authentication
- Login/Register with email validation
- JWT token management with refresh tokens
- Secure token storage
- Auto-login on app restart
- Password reset functionality

### 2. Real-time Messaging
- Socket.IO integration for real-time communication
- Message sending/receiving
- Typing indicators
- Message read receipts
- Online/offline status indicators

### 3. Chat Features
- Private and group chats
- Message pagination (load older messages)
- Message editing and deletion
- Reply to messages
- File and image sharing
- Search users functionality

### 4. UI/UX Requirements
- Modern Material Design
- Dark/Light theme support
- Smooth animations
- Pull-to-refresh for chat list
- Infinite scroll for messages
- Image preview and caching
- Push notifications (when messages received)

### 5. State Management
- Use Provider for state management
- Separate providers for Auth, Chat, and Theme
- Persistent storage for user preferences
- Efficient message caching

### 6. Error Handling
- Network error handling
- Retry mechanisms
- User-friendly error messages
- Offline mode support

### 7. Performance Optimization
- Lazy loading of chat rooms
- Message pagination
- Image caching
- Memory management for large chat histories

## Additional Implementation Notes

1. **Security**: Store JWT tokens securely using Flutter Secure Storage
2. **Validation**: Implement client-side validation matching backend requirements
3. **Offline Support**: Cache messages locally and sync when online
4. **Push Notifications**: Integrate Firebase Cloud Messaging for background notifications
5. **File Upload**: Implement image picker and file upload functionality
6. **Accessibility**: Ensure the app is accessible with proper semantic labels
7. **Testing**: Include unit tests for services and widget tests for UI components

Create a fully functional, production-ready Flutter app that provides an excellent user experience for real-time chat communication.