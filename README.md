# Real-time Chat Application Backend

A production-ready real-time chat application backend built with Node.js, TypeScript, Express, MongoDB, and Socket.io.

## Features

- **User Authentication**: JWT-based authentication with registration, login, and password reset
- **Real-time Messaging**: WebSocket communication using Socket.io
- **Chat Rooms**: Support for both private (1:1) and group chat rooms
- **Message Management**: Send, edit, delete messages with read receipts
- **User Management**: User profiles, online status, and user search
- **Type Safety**: Full TypeScript implementation
- **Security**: Rate limiting, input validation, password hashing
- **Testing**: Comprehensive unit and integration tests
- **Production Ready**: Docker support, logging, error handling

## Tech Stack

- **Runtime**: Node.js 18+
- **Language**: TypeScript
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Real-time**: Socket.io
- **Authentication**: JWT with bcrypt
- **Validation**: Joi
- **Testing**: Jest with Supertest
- **Logging**: Winston
- **Containerization**: Docker

## Getting Started

### Prerequisites

- Node.js 18+
- MongoDB
- Yarn package manager

### Installation

1. Install dependencies:
```bash
yarn install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env file with your configuration
```

3. Start development server:
```bash
yarn dev
```

### Environment Variables

Create a `.env` file based on `.env.example`:

```env
# Database
MONGODB_URI=mongodb://localhost:27017/chatapp

# JWT
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRE=7d

# Server
PORT=3000
NODE_ENV=development

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

## API Documentation

### Authentication Endpoints

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user profile
- `PUT /api/auth/me` - Update user profile
- `POST /api/auth/reset-password` - Initiate password reset
- `POST /api/auth/reset-password/:token` - Reset password with token

### User Endpoints

- `GET /api/users/me` - Get user profile
- `PUT /api/users/me` - Update user profile
- `GET /api/users/search` - Search users
- `GET /api/users/online` - Get online users
- `GET /api/users/:userId` - Get user by ID

### Chat Room Endpoints

- `POST /api/chatrooms` - Create chat room
- `GET /api/chatrooms` - Get user's chat rooms
- `GET /api/chatrooms/:roomId` - Get specific chat room
- `PUT /api/chatrooms/:roomId` - Update chat room
- `DELETE /api/chatrooms/:roomId` - Delete chat room
- `POST /api/chatrooms/:roomId/join` - Join chat room
- `POST /api/chatrooms/:roomId/leave` - Leave chat room

### Message Endpoints

- `POST /api/chatrooms/:roomId/messages` - Send message
- `GET /api/chatrooms/:roomId/messages` - Get messages (paginated)
- `PUT /api/chatrooms/messages/:messageId` - Edit message
- `DELETE /api/chatrooms/messages/:messageId` - Delete message
- `POST /api/chatrooms/:roomId/read` - Mark messages as read

## Socket.io Events

### Client to Server

- `joinRoom` - Join a chat room
- `leaveRoom` - Leave a chat room
- `sendMessage` - Send a message
- `typing` - Start typing indicator
- `stopTyping` - Stop typing indicator
- `messageRead` - Mark message as read
- `updateStatus` - Update online status

### Server to Client

- `connected` - Connection successful
- `newMessage` - New message received
- `userJoined` - User joined room
- `userLeft` - User left room
- `userTyping` - User typing status
- `messageRead` - Message read receipt
- `userStatusChanged` - User online status changed
- `error` - Error occurred

## Testing

Run tests:
```bash
# Unit tests
yarn test

# Integration tests
yarn test --testPathPattern=integration

# Test coverage
yarn test:coverage

# Watch mode
yarn test:watch
```

## Development Scripts

```bash
# Start development server with hot reload
yarn dev

# Build for production
yarn build

# Start production server
yarn start

# Run linting
yarn lint

# Fix linting issues
yarn lint:fix

# Format code
yarn format

# Check formatting
yarn format:check
```

## Docker

Build and run with Docker:

```bash
# Build image
docker build -t chat-app .

# Run container
docker run -p 3000:3000 --env-file .env chat-app
```

## Project Structure

```
src/
├── config/          # Configuration files
├── controllers/     # Route controllers
├── middleware/      # Express middleware
├── models/          # MongoDB models
├── routes/          # Express routes
├── services/        # Business logic
├── sockets/         # Socket.io handlers
├── utils/           # Utility functions
├── tests/           # Test files
├── app.ts           # Express app setup
└── server.ts        # Server entry point
```

## Security Features

- JWT authentication
- Password hashing with bcrypt
- Rate limiting
- Input validation and sanitization
- CORS configuration
- Helmet security headers
- Error handling without information leakage

## Production Considerations

- Environment-based configuration
- Comprehensive logging
- Error monitoring
- Database connection pooling
- Graceful shutdown handling
- Docker containerization
- Health check endpoints

## License

MIT License

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request