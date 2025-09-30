# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a real-time chat application backend built with Node.js, TypeScript, Express, MongoDB, and Socket.IO. The project follows a clean architecture pattern with clear separation of concerns across models, services, controllers, routes, and middleware.

## Development Commands

### Backend (from `/backend` directory)
```bash
# Development
npm run dev                 # Start development server with hot reload
npm run build              # Compile TypeScript to JavaScript
npm start                  # Start production server (requires build first)

# Testing
npm test                   # Run all tests once
npm run test:watch         # Run tests in watch mode
npm run test:coverage      # Run tests with coverage report

# Code Quality
npm run lint               # Check for linting errors
npm run lint:fix           # Fix auto-fixable linting errors
npm run format             # Format code with Prettier
npm run format:check       # Check if code is properly formatted
```

### Running Individual Tests
```bash
# Run specific test file
npm test -- src/tests/unit/models/User.test.ts

# Run tests matching a pattern
npm test -- --testNamePattern="AuthService"

# Run integration tests only
npm test -- src/tests/integration/
```

## Architecture Overview

### Core Application Structure
- **Entry Point**: `src/server.ts` - Bootstraps the application, connects to database, sets up Socket.IO
- **App Configuration**: `src/app.ts` - Express app factory with middleware setup
- **Environment Config**: `src/config/environment.ts` - Centralized configuration with Joi validation

### Data Layer
- **Models** (`src/models/`): Mongoose schemas with business logic methods
  - `User.ts` - User authentication and profile management
  - `ChatRoom.ts` - Private/group chat room management with participant handling
  - `Message.ts` - Real-time messaging with read receipts and status tracking
- **Database Config** (`src/config/database.ts`): MongoDB connection management

### Business Logic Layer
- **Services** (`src/services/`): Core business logic separated from HTTP concerns
  - `authService.ts` - JWT token management, password hashing
  - `chatService.ts` - Message operations, chat room management
- **Controllers** (`src/controllers/`): HTTP request/response handling
  - Follow consistent error handling patterns
  - Use validation schemas from `@/utils/validation.ts`

### API Layer
- **Routes** (`src/routes/`): Express route definitions with middleware
  - `authRoutes.ts` - Authentication endpoints (register, login, password reset)
  - `userRoutes.ts` - User profile and search operations
  - `chatroomRoutes.ts` - Chat room CRUD and message operations
- **Middleware** (`src/middleware/`): Cross-cutting concerns
  - Authentication, rate limiting, error handling, request logging

### Real-time Communication
- **Socket Events** (`src/sockets/chatEvents.ts`): WebSocket event handlers for:
  - Room joining/leaving
  - Real-time messaging
  - Typing indicators
  - Read receipts
  - Online status updates

### Path Aliases
The project uses TypeScript path mapping with `@/` prefix:
```typescript
import { User } from '@/models';
import { authService } from '@/services';
import { authenticateToken } from '@/middleware';
```

## Key Patterns and Conventions

### Error Handling
- All async operations use try-catch blocks
- Consistent error response format via `globalErrorHandler`
- Custom error classes for different error types
- Request IDs for tracing across logs

### Authentication Flow
- JWT-based authentication with refresh tokens
- Token validation middleware (`authenticateToken`)
- Password hashing with bcrypt (salt rounds: 12)
- Rate limiting on auth endpoints

### Database Operations
- Mongoose with TypeScript interfaces
- Pre-save middleware for password hashing
- Indexed fields for performance
- Aggregation pipelines for complex queries

### Socket.IO Architecture
- Authentication middleware for socket connections
- Room-based messaging with participant validation
- Event validation using Joi schemas
- Graceful error handling and user feedback

### Testing Strategy
- Jest with ts-jest preset
- MongoDB Memory Server for isolated testing
- Separate unit and integration test suites
- Test setup in `src/tests/setup.ts`

## Environment Setup

### Required Environment Variables
```bash
# Database
MONGODB_URI=mongodb://localhost:27017/chatapp

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRE=7d

# Server Configuration
PORT=3000
NODE_ENV=development

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

### Database Schema Relationships
- **User** ↔ **ChatRoom**: Many-to-many relationship via `participants` array
- **ChatRoom** ↔ **Message**: One-to-many relationship via `chatRoomId`
- **User** ↔ **Message**: One-to-many relationship via `senderId`
- **Message** ↔ **Message**: Self-referencing via `replyTo` for message replies

### Key Business Rules
- Private chats: Exactly 2 participants, no name required
- Group chats: Minimum 3 participants, name required
- Message read tracking: Individual read receipts per user
- Online status: Real-time updates via Socket.IO events
- Rate limiting: Separate limits for auth, search, and messaging endpoints

## Mobile App Integration
The `FLUTTER_MOBILE_APP_PROMPT.md` file contains comprehensive API documentation and WebSocket event specifications for Flutter mobile app development. All backend endpoints and real-time events are fully documented with request/response examples.