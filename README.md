# Real-Time Chat Application

[![Tests](https://github.com/kallyas/chat-app-backend/actions/workflows/ci.yml/badge.svg)](https://github.com/kallyas/chat-app-backend/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/kallyas/chat-app-backend/graph/badge.svg?token=81KYBVzPSw)](https://codecov.io/gh/kallyas/chat-app-backend)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern, scalable real-time chat application built with Node.js, TypeScript, Express, MongoDB, and Socket.IO. Features secure authentication, private/group messaging, typing indicators, read receipts, and comprehensive rate limiting.

## ✨ Features

### Core Functionality
- 🔐 **Secure Authentication**: JWT-based auth with token versioning and refresh tokens
- 💬 **Real-Time Messaging**: Instant message delivery with Socket.IO
- 👥 **Private & Group Chats**: Support for one-on-one and group conversations
- ✅ **Read Receipts**: Track message read status per user
- ✍️ **Typing Indicators**: Real-time typing status updates
- 🔄 **Message Editing & Deletion**: Edit/delete messages within configurable time limits
- 🔍 **User Search**: Search users by username or email with pagination
- 🟢 **Online Status**: Real-time user presence tracking

### Security & Performance
- 🛡️ **Rate Limiting**: Comprehensive rate limiting on both REST and Socket.IO
- 🔒 **Timing Attack Protection**: Prevents username enumeration
- 🚀 **N+1 Query Optimization**: Efficient database queries with aggregation
- 📊 **Pagination**: Validated pagination on all list endpoints
- 🎯 **Input Validation**: Joi schema validation throughout
- 🔑 **Token Invalidation**: Automatic token invalidation on password change

### Developer Experience
- 📝 **TypeScript**: Full type safety
- 🧪 **Comprehensive Tests**: 79+ tests with high coverage
- 📋 **Structured Logging**: Winston logger with test/dev/prod configs
- 🔄 **Hot Reload**: Development server with nodemon
- 📚 **API Documentation**: Complete API specs for mobile integration

## 🏗️ Architecture

```
chat-app/
├── backend/                 # Node.js/Express backend
│   ├── src/
│   │   ├── config/         # Configuration (DB, logger, env)
│   │   ├── controllers/    # Request handlers
│   │   ├── middleware/     # Auth, rate limiting, error handling
│   │   ├── models/         # Mongoose schemas
│   │   ├── routes/         # API route definitions
│   │   ├── services/       # Business logic
│   │   ├── sockets/        # Socket.IO event handlers
│   │   ├── types/          # TypeScript types
│   │   └── utils/          # Helper functions
│   └── tests/              # Unit and integration tests
└── .github/workflows/      # CI/CD pipelines
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ (tested on 18, 20, 22)
- MongoDB 5.0+
- Yarn (recommended) or npm

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kallyas/chat-app.git
   cd chat-app
   ```

2. **Install dependencies**
   ```bash
   cd backend
   yarn install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Start development server**
   ```bash
   yarn dev
   ```

The server will start on `http://localhost:3000`

### Environment Variables

```env
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

# Message Time Limits (hours)
MESSAGE_EDIT_TIME_LIMIT_HOURS=24
MESSAGE_DELETE_TIME_LIMIT_HOURS=168

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

## 🧪 Testing

```bash
# Run all tests
yarn test

# Run tests in watch mode
yarn test:watch

# Generate coverage report
yarn test:coverage

# Run specific test file
yarn test -- src/tests/unit/models/User.test.ts

# Run linter
yarn lint

# Fix linting issues
yarn lint:fix
```

### Test Results
```
Test Suites: 5 passed, 5 total
Tests:       79 passed, 79 total
Snapshots:   0 total
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user profile
- `PUT /api/auth/me` - Update user profile
- `POST /api/auth/forgot-password` - Initiate password reset
- `POST /api/auth/reset-password/:token` - Reset password

### Users
- `GET /api/users/search` - Search users (with pagination)
- `GET /api/users/online` - Get online users (with pagination)

### Chat Rooms
- `POST /api/chatrooms` - Create chat room
- `GET /api/chatrooms` - Get user's chat rooms (with pagination)
- `GET /api/chatrooms/:roomId` - Get specific chat room
- `PUT /api/chatrooms/:roomId` - Update chat room
- `DELETE /api/chatrooms/:roomId` - Delete chat room
- `POST /api/chatrooms/:roomId/leave` - Leave chat room

### Messages
- `POST /api/chatrooms/:roomId/messages` - Send message
- `GET /api/chatrooms/:roomId/messages` - Get messages (with pagination)
- `PUT /api/messages/:messageId` - Edit message
- `DELETE /api/messages/:messageId` - Delete message

## 🔌 Socket.IO Events

### Client → Server
- `joinRoom` - Join a chat room
- `leaveRoom` - Leave a chat room
- `sendMessage` - Send a message
- `typing` - Send typing indicator
- `stopTyping` - Stop typing indicator
- `messageRead` - Mark message as read
- `updateStatus` - Update online status

### Server → Client
- `newMessage` - New message received
- `userJoined` - User joined room
- `userLeft` - User left room
- `userTyping` - User typing status
- `messageRead` - Message read receipt
- `userStatusChanged` - User online status changed
- `error` - Error notification

## 🔒 Security Features

1. **Authentication**
   - JWT with token versioning
   - Password hashing with bcrypt (12 rounds)
   - Token invalidation on password change

2. **Rate Limiting**
   - REST API: 100 req/15min (configurable per endpoint)
   - Socket.IO: Per-event limits (30 msg/min, 10 typing/min)
   - Automatic disconnection on abuse

3. **Input Validation**
   - Joi schema validation
   - MongoDB ObjectId validation
   - Room membership checks

4. **Attack Prevention**
   - Timing attack protection (constant-time operations)
   - Username enumeration prevention
   - XSS protection with sanitization

## 📊 Performance Optimizations

- **N+1 Query Elimination**: MongoDB aggregation pipelines
- **Efficient Indexing**: Optimized indexes on ChatRoom.participants
- **Pagination Validation**: Max limit enforcement (100 items)
- **Connection Pooling**: MongoDB connection management
- **Sorted Participants**: Consistent ordering for private chat deduplication

## 📝 Logging

Comprehensive logging with Winston:

- **Development**: Colorized console + debug files
- **Test**: Silent console + separate test log files
- **Production**: JSON logs with rotation

See [LOGGING.md](backend/LOGGING.md) for details.

## 🔧 Development

```bash
# Start development server with hot reload
yarn dev

# Build for production
yarn build

# Start production server
yarn start

# Format code
yarn format

# Check formatting
yarn format:check
```

## 🚢 Production Deployment

1. **Build the application**
   ```bash
   yarn build
   ```

2. **Set production environment variables**
   ```bash
   export NODE_ENV=production
   export MONGODB_URI=<your-production-mongodb-uri>
   export JWT_SECRET=<strong-random-secret>
   ```

3. **Start the server**
   ```bash
   yarn start
   ```

### Docker Deployment (Optional)

```bash
docker build -t chat-app .
docker run -p 3000:3000 --env-file .env chat-app
```

## 📱 Mobile Integration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow TypeScript best practices
- Write tests for new features
- Maintain test coverage above 80%
- Follow the existing code style (enforced by ESLint)
- Update documentation for API changes

## 🐛 Issues Fixed

This version includes fixes for 11+ critical issues:
- ✅ Socket.IO rate limiting
- ✅ N+1 query optimization
- ✅ Message edit/delete time limits
- ✅ Timing attack prevention
- ✅ Pagination validation
- ✅ Database indexing
- ✅ Email validation
- ✅ Token invalidation
- ✅ Socket event validation
- ✅ Race condition fixes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Kallyas** - [GitHub](https://github.com/kallyas)

## 🙏 Acknowledgments

- Built with [Express.js](https://expressjs.com/)
- Real-time communication via [Socket.IO](https://socket.io/)
- Database powered by [MongoDB](https://www.mongodb.com/)
- Testing with [Jest](https://jestjs.io/)
- Logging with [Winston](https://github.com/winstonjs/winston)

## 📞 Support

For support, open an issue on GitHub.

---

⭐ Star this repo if you find it helpful!
