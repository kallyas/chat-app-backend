# Mobile App Update TODO List

This document outlines all the changes needed in the mobile app to align with the backend updates and bug fixes implemented in v1.0.0.

## 🔴 Critical Changes (Breaking Changes)

### 1. Authentication Error Messages Updated
**Backend Change**: Generic error messages to prevent username enumeration

**Mobile Updates Required**:
- [ ] **Update error message handling** in login screen
  - Old: "Invalid email or password"
  - New: "Invalid credentials"

- [ ] **Update error message handling** in registration screen
  - Old: "Email already registered" or "Username already taken"
  - New: "Account already exists with provided credentials"

**Files to Update**:
```
lib/screens/auth/login_screen.dart
lib/screens/auth/register_screen.dart
lib/services/auth_service.dart
```

**Example Change**:
```dart
// Before
if (error.contains('Invalid email or password')) {
  showError('Invalid email or password');
}

// After
if (error.contains('Invalid credentials')) {
  showError('Invalid credentials. Please check your email and password.');
}
```

---

### 2. Token Invalidation on Password Change
**Backend Change**: Tokens now include `tokenVersion` and are invalidated on password change

**Mobile Updates Required**:
- [ ] **Handle token invalidation** - User will be logged out after password change
- [ ] **Show notification** when token is invalidated with message:
  - "Your session has expired. Please login again."
  - "Token has been invalidated. Please login again."

- [ ] **Auto-redirect to login** on 401 with token invalidation message
- [ ] **Clear local storage** when receiving invalidation error

**Files to Update**:
```
lib/services/auth_service.dart
lib/services/api_interceptor.dart
lib/providers/auth_provider.dart
lib/screens/settings/change_password_screen.dart
```

**Example Implementation**:
```dart
// In API Interceptor
if (response.statusCode == 401 &&
    response.data['message'].contains('invalidated')) {
  // Clear tokens
  await _authService.clearTokens();
  // Navigate to login
  Get.offAll(() => LoginScreen());
  Get.snackbar(
    'Session Expired',
    'Please login again',
    backgroundColor: Colors.red,
  );
}
```

---

### 3. Message Edit/Delete Time Limits Now Enforced
**Backend Change**: Configurable time limits (24h edit, 168h delete)

**Mobile Updates Required**:
- [ ] **Update error handling** for edit/delete operations
  - Old: "Message is too old to edit"
  - New: "Messages can only be edited within 24 hours"
  - New: "Messages can only be deleted within 168 hours"

- [ ] **Add visual indicators** showing if message can be edited/deleted
- [ ] **Display countdown timer** (optional) showing time remaining
- [ ] **Disable edit/delete buttons** for old messages

**Files to Update**:
```
lib/widgets/message_widget.dart
lib/screens/chat/chat_room_screen.dart
lib/services/message_service.dart
lib/models/message.dart
```

**Example Implementation**:
```dart
class Message {
  DateTime createdAt;

  bool get canEdit {
    final age = DateTime.now().difference(createdAt);
    return age.inHours < 24;
  }

  bool get canDelete {
    final age = DateTime.now().difference(createdAt);
    return age.inHours < 168;
  }

  String get editTimeRemaining {
    final age = DateTime.now().difference(createdAt);
    final remaining = 24 - age.inHours;
    return remaining > 0 ? '$remaining hours' : 'Expired';
  }
}

// In MessageWidget
IconButton(
  icon: Icon(Icons.edit),
  onPressed: message.canEdit ? () => editMessage() : null,
  tooltip: message.canEdit
    ? 'Edit message'
    : 'Can only edit within 24 hours',
)
```

---

## 🟡 Important Changes (New Features/Enhancements)

### 4. Socket.IO Rate Limiting
**Backend Change**: Rate limits on all Socket.IO events

**Mobile Updates Required**:
- [ ] **Handle rate limit errors** from Socket.IO
  - Error message: "Rate limit exceeded. Please slow down."

- [ ] **Implement exponential backoff** for retries
- [ ] **Show user-friendly messages** when rate limited
- [ ] **Debounce typing indicators** (max 10/min)
- [ ] **Queue messages** if rate limited instead of failing

**Files to Update**:
```
lib/services/socket_service.dart
lib/screens/chat/chat_room_screen.dart
lib/widgets/typing_indicator.dart
```

**Example Implementation**:
```dart
class SocketService {
  final _messageQueue = Queue<Message>();
  DateTime? _lastTypingEvent;

  void sendTypingIndicator(String roomId, bool isTyping) {
    // Throttle typing events to max 1 per 6 seconds (10/min)
    final now = DateTime.now();
    if (_lastTypingEvent != null &&
        now.difference(_lastTypingEvent!) < Duration(seconds: 6)) {
      return; // Skip this event
    }

    _lastTypingEvent = now;
    socket.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  void _handleError(dynamic error) {
    if (error['message'].contains('Rate limit exceeded')) {
      Get.snackbar(
        'Slow Down',
        'You\'re sending messages too quickly. Please wait a moment.',
        duration: Duration(seconds: 3),
      );
    }
  }
}
```

---

### 5. Pagination Updates
**Backend Change**: Validated pagination with max limit of 100

**Mobile Updates Required**:
- [ ] **Update pagination requests** to respect max limit
- [ ] **Handle pagination errors** for invalid parameters
- [ ] **Ensure limit ≤ 100** in all paginated requests

**Affected Endpoints**:
- `GET /api/chatrooms` (chat room list)
- `GET /api/chatrooms/:roomId/messages` (messages)
- `GET /api/users/search` (user search)
- `GET /api/users/online` (online users)

**Files to Update**:
```
lib/services/chat_service.dart
lib/services/user_service.dart
lib/services/message_service.dart
```

**Example Implementation**:
```dart
Future<List<ChatRoom>> getChatRooms({int page = 1, int limit = 20}) async {
  // Enforce max limit
  final validLimit = limit > 100 ? 100 : limit;

  final response = await _api.get('/chatrooms', queryParameters: {
    'page': page,
    'limit': validLimit,
  });

  return ChatRoomResponse.fromJson(response.data);
}
```

---

### 6. Email Validation Relaxed
**Backend Change**: Now accepts modern TLDs and plus-addressing

**Mobile Updates Required**:
- [ ] **Update email validation regex** to match backend
- [ ] **Remove overly restrictive validation**
- [ ] **Allow plus-addressing** (user+tag@domain.com)
- [ ] **Allow TLDs > 3 characters** (.email, .photography, etc.)

**Files to Update**:
```
lib/utils/validators.dart
lib/screens/auth/register_screen.dart
lib/screens/settings/profile_screen.dart
```

**Example Implementation**:
```dart
class Validators {
  // Old - Too restrictive
  // static final emailRegex = RegExp(r'^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$');

  // New - Matches backend
  static final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}
```

---

### 7. Socket Authentication Enhanced
**Backend Change**: Token version validation on socket connection

**Mobile Updates Required**:
- [ ] **Handle socket auth errors** for invalidated tokens
  - Error: "Token has been invalidated. Please login again."

- [ ] **Auto-reconnect logic** should check token validity first
- [ ] **Clear session and redirect** on token invalidation error

**Files to Update**:
```
lib/services/socket_service.dart
lib/services/auth_service.dart
```

**Example Implementation**:
```dart
void _initSocket() {
  socket = io(baseUrl, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
    'auth': {
      'token': _authService.accessToken,
    },
  });

  socket.on('connect_error', (error) {
    if (error.toString().contains('invalidated')) {
      _authService.logout();
      Get.offAll(() => LoginScreen());
      Get.snackbar(
        'Session Expired',
        'Your session has expired. Please login again.',
      );
    }
  });
}
```

---

### 8. Enhanced Room Validation
**Backend Change**: Typing and leaveRoom events now validate room membership

**Mobile Updates Required**:
- [ ] **Handle validation errors** for typing events
  - Error: "Room not found or access denied"

- [ ] **Handle validation errors** for leave room
  - Error: "Invalid room ID format"

- [ ] **Update error UI** to show meaningful messages

**Files to Update**:
```
lib/services/socket_service.dart
lib/screens/chat/chat_room_screen.dart
```

---

## 🟢 Optional Improvements (Recommended)

### 9. Race Condition Fix Awareness
**Backend Change**: Multiple socket connections handled correctly with `activeSocketCount`

**Mobile Updates Required** (Optional):
- [ ] **No changes required** - Backend handles this automatically
- [ ] **Optional**: Show notification if online status updates are delayed
- [ ] **Optional**: Implement connection status indicator

---

### 10. N+1 Query Optimization
**Backend Change**: Chat room listing is now much faster

**Mobile Updates Required**:
- [ ] **No code changes required** - API response structure unchanged
- [ ] **Optional**: Reduce loading timeouts as backend is faster
- [ ] **Optional**: Increase default page size (max 100)

---

## 📋 Testing Checklist

### Authentication Flow
- [ ] Test registration with existing email (should show generic error)
- [ ] Test login with wrong password (should show "Invalid credentials")
- [ ] Test login with wrong email (should show "Invalid credentials")
- [ ] Test password change (should invalidate tokens and logout)
- [ ] Test password reset (should invalidate tokens)
- [ ] Test email validation with plus-addressing (user+tag@gmail.com)
- [ ] Test email validation with long TLDs (.photography, .email)

### Messaging
- [ ] Test editing message after 24 hours (should fail)
- [ ] Test deleting message after 168 hours (should fail)
- [ ] Test edit/delete buttons disabled for old messages
- [ ] Test rapid message sending (should be rate limited)
- [ ] Test typing indicator throttling

### Socket.IO
- [ ] Test rapid typing (should not exceed 10/min)
- [ ] Test rapid room join/leave (should be rate limited)
- [ ] Test socket connection with invalidated token (should fail)
- [ ] Test multiple device connections (online status should work correctly)

### Pagination
- [ ] Test chat rooms with limit > 100 (should cap at 100)
- [ ] Test messages with negative page numbers (should default to 1)
- [ ] Test user search with invalid pagination

---

## 🔧 Implementation Priority

### Phase 1: Critical (Do First)
1. ✅ Update authentication error messages
2. ✅ Handle token invalidation
3. ✅ Update message time limit handling
4. ✅ Handle Socket.IO rate limiting

### Phase 2: Important (Do Next)
5. ✅ Update pagination limits
6. ✅ Update email validation
7. ✅ Enhanced socket authentication

### Phase 3: Polish (Do Last)
8. ✅ UI improvements for time limits
9. ✅ Better error messages
10. ✅ Connection status indicators

---

## 📁 Files Summary

### High Priority Files
```
lib/services/
  ├── auth_service.dart          (Token handling, error messages)
  ├── socket_service.dart        (Rate limiting, validation)
  └── api_interceptor.dart       (Token invalidation handling)

lib/screens/auth/
  ├── login_screen.dart          (Error message updates)
  └── register_screen.dart       (Error message updates)

lib/widgets/
  └── message_widget.dart        (Edit/delete time limits)
```

### Medium Priority Files
```
lib/services/
  ├── chat_service.dart          (Pagination)
  ├── message_service.dart       (Time limits, pagination)
  └── user_service.dart          (Pagination)

lib/utils/
  └── validators.dart            (Email validation)
```

---

## 🚀 Deployment Strategy

1. **Backend First**: Deploy updated backend (already done)
2. **Mobile Update**: Update mobile app with changes above
3. **Gradual Rollout**:
   - Beta test with small group
   - Monitor error rates
   - Full rollout after 48 hours
4. **User Communication**:
   - In-app notification about improvements
   - Force update if critical (token invalidation)

---

## 📞 Support

If you encounter issues during implementation:
- Check backend API documentation: `backend/FLUTTER_MOBILE_APP_PROMPT.md`
- Review backend changelog: `CHANGELOG.md`
- Create issue with label `mobile-app`

---

## ✅ Sign-off Checklist

Before releasing mobile app update:
- [ ] All critical changes implemented
- [ ] All tests passing
- [ ] Error handling tested
- [ ] Token invalidation flow tested
- [ ] Rate limiting tested
- [ ] Pagination tested
- [ ] Email validation tested
- [ ] Beta testing completed
- [ ] Crash analytics clean
- [ ] Performance metrics acceptable
- [ ] User documentation updated

---

**Estimated Implementation Time**: 8-12 hours for experienced Flutter developer
**Testing Time**: 4-6 hours
**Total**: 12-18 hours
