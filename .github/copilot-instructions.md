# GitHub Copilot Instructions

This file provides instructions for GitHub Copilot when working with code in this repository.

## Project Overview

This is a **real-time chat application** with:
- **Backend**: Node.js + TypeScript + Express + MongoDB + Socket.IO (`/backend`)
- **Mobile App**: Flutter + Dart (`/mobile`)

The project follows a **clean architecture pattern** with clear separation of concerns.

## Repository Structure

```
chat-app-backend/
├── backend/              # Node.js/TypeScript backend
│   ├── src/
│   │   ├── models/      # Mongoose schemas
│   │   ├── services/    # Business logic
│   │   ├── controllers/ # HTTP handlers
│   │   ├── routes/      # API endpoints
│   │   ├── middleware/  # Express middleware
│   │   ├── sockets/     # Socket.IO event handlers
│   │   ├── config/      # Configuration
│   │   └── tests/       # Jest tests
│   ├── package.json
│   └── tsconfig.json
├── mobile/              # Flutter mobile app
│   ├── lib/
│   │   ├── models/      # Data models
│   │   ├── services/    # API & Socket services
│   │   ├── providers/   # State management
│   │   ├── screens/     # UI screens
│   │   └── widgets/     # Reusable components
│   └── pubspec.yaml
├── CLAUDE.md            # Detailed architecture docs
└── .github/
    └── copilot-instructions.md  # This file
```

## Backend Development

### Tech Stack
- **Runtime**: Node.js 18+
- **Language**: TypeScript with strict mode
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Real-time**: Socket.IO
- **Authentication**: JWT with bcrypt
- **Testing**: Jest with ts-jest
- **Logging**: Winston

### Development Commands (from `/backend`)
```bash
npm run dev          # Start development server with hot reload
npm run build        # Compile TypeScript
npm start            # Start production server
npm test             # Run all tests
npm run test:watch   # Watch mode for tests
npm run lint         # Check linting
npm run lint:fix     # Fix linting issues
npm run format       # Format with Prettier
```

### Path Aliases
Use TypeScript path mapping with `@/` prefix:
```typescript
import { User } from '@/models';
import { authService } from '@/services';
import { authenticateToken } from '@/middleware';
```

### Coding Patterns

#### Error Handling
- Always use try-catch blocks for async operations
- Use consistent error response format via `globalErrorHandler`
- Include request IDs for tracing

```typescript
try {
  // async operation
} catch (error) {
  logger.error('Operation failed', { error, requestId });
  throw new AppError('User-friendly message', 500);
}
```

#### Authentication
- JWT-based with refresh tokens
- Password hashing with bcrypt (salt rounds: 12)
- Token validation via `authenticateToken` middleware
- Rate limiting on auth endpoints

#### Database Operations
- Use Mongoose with TypeScript interfaces
- Implement pre-save middleware for data transformation
- Use indexed fields for performance
- Prefer aggregation pipelines for complex queries

#### Socket.IO Events
- Authenticate socket connections
- Validate participants before emitting to rooms
- Use Joi schemas for event validation
- Provide user-friendly error messages

### Testing Guidelines
- Use Jest with ts-jest preset
- MongoDB Memory Server for isolated testing
- Separate unit and integration tests
- Test setup in `src/tests/setup.ts`

```typescript
// Example test structure
describe('AuthService', () => {
  it('should register new user', async () => {
    // arrange
    const userData = { email: 'test@example.com', password: 'password123' };
    
    // act
    const result = await authService.register(userData);
    
    // assert
    expect(result.user).toBeDefined();
    expect(result.token).toBeDefined();
  });
});
```

## Mobile Development

### Tech Stack
- **Framework**: Flutter 3.0+
- **Language**: Dart 2.17+
- **State Management**: Provider
- **Storage**: flutter_secure_storage
- **HTTP Client**: dio
- **Real-time**: socket_io_client

### Development Commands (from `/mobile`)
```bash
flutter pub get      # Install dependencies
flutter run          # Run in debug mode
flutter build apk    # Build Android APK
flutter build ios    # Build iOS app
flutter test         # Run tests
flutter analyze      # Static analysis
```

### Coding Patterns

#### State Management
Use Provider pattern for state:
```dart
// In provider
class AuthProvider extends ChangeNotifier {
  User? _user;
  
  Future<void> login(String email, String password) async {
    _user = await authService.login(email, password);
    notifyListeners();
  }
}

// In widget
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Text(authProvider.user?.name ?? 'Guest');
  },
)
```

#### API Integration
- Use dio for HTTP requests with interceptors
- Handle JWT token refresh automatically
- Implement proper error handling

#### Socket.IO Integration
- Connect after authentication
- Handle reconnection automatically
- Clean up listeners on dispose

#### UI Guidelines
- Follow Material Design 3
- Support dark/light themes
- Use responsive layouts
- Implement smooth animations

## Key Business Rules

### Chat Rooms
- **Private chats**: Exactly 2 participants, no name required
- **Group chats**: Minimum 3 participants, name required

### Messages
- Individual read receipts per user
- Support for message replies (via `replyTo` field)
- Message status tracking (sent, delivered, read)

### Authentication
- JWT token expiration: 7 days
- Automatic token refresh on API calls
- Secure storage for tokens

## Environment Setup

### Backend Environment Variables
```bash
MONGODB_URI=mongodb://localhost:27017/chatapp
JWT_SECRET=your-secret-key
JWT_EXPIRE=7d
PORT=3000
NODE_ENV=development
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

### Mobile Configuration
Update `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
static const String socketUrl = 'http://localhost:3000';
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/me` - Update profile

### Chat Rooms
- `POST /api/chatrooms` - Create room
- `GET /api/chatrooms` - List user's rooms
- `GET /api/chatrooms/:roomId` - Get room details
- `POST /api/chatrooms/:roomId/messages` - Send message

### Users
- `GET /api/users/search` - Search users
- `GET /api/users/:userId` - Get user profile

## Socket.IO Events

### Client → Server
- `joinRoom` - Join a chat room
- `leaveRoom` - Leave a chat room
- `sendMessage` - Send a message
- `typing` - Typing indicator
- `messageRead` - Mark message as read

### Server → Client
- `connected` - Connection successful
- `newMessage` - New message received
- `userJoined` - User joined room
- `userLeft` - User left room
- `userTyping` - User typing status
- `messageRead` - Message read receipt

## Database Schema

### Relationships
- **User** ↔ **ChatRoom**: Many-to-many via `participants` array
- **ChatRoom** ↔ **Message**: One-to-many via `chatRoomId`
- **User** ↔ **Message**: One-to-many via `senderId`
- **Message** ↔ **Message**: Self-referencing via `replyTo`

## Additional Resources

- See `CLAUDE.md` for comprehensive architecture details
- See `backend/README.md` for backend-specific documentation
- See `mobile/README.md` for mobile app documentation
- See `FLUTTER_MOBILE_APP_PROMPT.md` for mobile API integration guide

## Code Quality Standards

### TypeScript (Backend)
- Use strict TypeScript mode
- Avoid `any` types; prefer proper interfaces
- Document complex functions with JSDoc
- Follow ESLint rules configured in `.eslintrc.json`
- Format code with Prettier

### Dart (Mobile)
- Follow Dart style guide
- Use const constructors where possible
- Implement proper null safety
- Use meaningful widget names
- Keep widgets small and focused

## Security Considerations

- Never commit secrets or API keys
- Always validate user input (both client and server)
- Implement rate limiting on sensitive endpoints
- Use parameterized queries to prevent injection
- Sanitize error messages to prevent information leakage
- Use HTTPS in production
- Implement proper CORS configuration

## Performance Guidelines

### Backend
- Use database indexes on frequently queried fields
- Implement pagination for list endpoints
- Use connection pooling for database
- Cache frequently accessed data
- Use aggregation pipelines for complex queries

### Mobile
- Implement infinite scroll for message history
- Cache user profiles and chat rooms
- Optimize image loading and caching
- Minimize rebuilds with proper state management
- Use const constructors to reduce rebuilds

## Common Patterns to Follow

### Backend Validation
```typescript
// Use Joi for validation
const schema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
});

const { error, value } = schema.validate(req.body);
if (error) {
  throw new ValidationError(error.details[0].message);
}
```

### Mobile Error Handling
```dart
try {
  final result = await apiService.makeRequest();
  // handle success
} on DioException catch (e) {
  // Handle HTTP errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.response?.data['message'] ?? 'Error occurred')),
  );
} catch (e) {
  // Handle other errors
  logger.error('Unexpected error: $e');
}
```

## When Making Changes

### For Backend Changes
1. Update models if schema changes
2. Update services for business logic
3. Update controllers for HTTP handling
4. Update routes if new endpoints
5. Add/update tests
6. Update API documentation if endpoints change

### For Mobile Changes
1. Update models if API response changes
2. Update services for API/socket changes
3. Update providers for state changes
4. Update screens/widgets for UI changes
5. Test on both platforms (iOS & Android)
6. Check theme compatibility (light/dark)

## Debugging Tips

### Backend
- Check logs in `logs/` directory
- Use Winston logger with appropriate levels
- Test endpoints with `api-tests.http` file
- Use MongoDB Compass for database inspection

### Mobile
- Use Flutter DevTools for performance
- Check console logs for errors
- Test Socket.IO connection separately
- Verify API endpoint configuration

## Testing Strategy

### Backend Tests
- Unit tests for services and utilities
- Integration tests for API endpoints
- Socket.IO event testing
- Mock external dependencies

### Mobile Tests
- Widget tests for UI components
- Unit tests for models and services
- Integration tests for complete flows
- Use mockito for mocking services

---

**Note**: This file provides guidance for GitHub Copilot. For comprehensive architectural details and development guidelines, see `CLAUDE.md`.
