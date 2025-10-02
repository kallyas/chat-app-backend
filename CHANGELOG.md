# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-02

### Added

#### Security Enhancements
- **Socket.IO Rate Limiting**: Comprehensive rate limiting for all Socket.IO events
  - `sendMessage`: 30 requests/minute
  - `typing`/`stopTyping`: 10 requests/minute
  - `joinRoom`/`leaveRoom`: 20 requests/minute
  - `updateStatus`: 5 requests/minute
  - `messageRead`: 60 requests/minute
  - Automatic socket disconnection on abuse

- **Token Versioning**: Automatic token invalidation on password change
  - Added `tokenVersion` field to User model
  - Tokens invalidated on password update or reset
  - Prevents session hijacking after password change

- **Timing Attack Protection**: Prevents username enumeration
  - Constant-time operations for authentication
  - Generic error messages for login/registration
  - Dummy password hashing for non-existent users

- **Input Validation**: Enhanced validation across all endpoints
  - Socket.IO event validation (roomId, membership checks)
  - Pagination parameter validation (max limit: 100)
  - ObjectId format validation

#### Performance Optimizations
- **N+1 Query Elimination**: MongoDB aggregation pipelines
  - Reduced `getUserChatRooms` from 1+2N queries to 1 query
  - Significant performance improvement for chat room listing

- **Database Indexing**: Optimized ChatRoom.participants index
  - Sorted participants for private chats
  - Consistent ordering for index optimization
  - O(log n) duplicate detection

#### Features
- **Configurable Message Time Limits**
  - Edit limit: 24 hours (configurable via env)
  - Delete limit: 168 hours (configurable via env)
  - Clear error messages with time information

- **Improved Email Validation**
  - Supports modern TLDs (4+ characters)
  - Accepts plus-addressing (user+tag@domain.com)
  - RFC 5322 compliant

- **Race Condition Fix**: Socket authentication status
  - Added `activeSocketCount` to User model
  - Only sets offline when last connection closes
  - Prevents premature offline status

#### Testing & Logging
- **Test Log Configuration**: Comprehensive test logging
  - Silent console output during tests
  - Separate test log files (debug, app, error)
  - 7-day retention for test logs

- **GitHub Actions**: Complete CI/CD pipeline
  - Tests on Node 18, 20, 22
  - Automated linting and formatting checks
  - Code coverage reporting to Codecov
  - Test log artifact upload on failure

#### Documentation
- **Root README.md**: Comprehensive project documentation
- **CONTRIBUTING.md**: Contribution guidelines
- **LOGGING.md**: Logging configuration guide
- **LICENSE**: MIT License
- **GitHub Templates**: PR and issue templates
- **CHANGELOG.md**: This file

### Changed
- Updated authentication error messages for security
  - "Email already registered" → "Account already exists"
  - "Invalid email or password" → "Invalid credentials"
- Modified logger configuration for test environment
- Updated package.json license from ISC to MIT

### Fixed
- **Issue #21**: Missing rate limiting on Socket.IO events
- **Issue #20**: N+1 query problem in getUserChatRooms
- **Issue #19**: Message edit time limit not enforced consistently
- **Issue #18**: Username enumeration via timing attack
- **Issue #17**: No pagination validation in query parameters
- **Issue #16**: Missing index on ChatRoom.participants
- **Issue #15**: Email regex validation too restrictive
- **Issue #14**: Password update doesn't invalidate existing tokens
- **Issue #13**: Typing event doesn't validate roomId or check membership
- **Issue #12**: Missing input validation in Socket.IO leaveRoom event
- **Issue #11**: Race condition in Socket.IO authentication status updates

### Test Results
```
Test Suites: 5 passed, 5 total
Tests:       79 passed, 79 total
Snapshots:   0 total
Time:        ~26s
```

### Security Improvements
- Eliminated 5 security vulnerabilities
- Added 3 layers of rate limiting (REST, Socket.IO per-event, user-based)
- Implemented timing attack protection
- Enhanced input validation across all endpoints

### Performance Improvements
- 95%+ reduction in database queries for chat room listing
- Optimized database indexes
- Efficient pagination with validation

---

## [0.1.0] - Initial Release

### Added
- Basic chat functionality
- User authentication
- Real-time messaging with Socket.IO
- MongoDB integration
- TypeScript support
- Jest testing framework

[1.0.0]: https://github.com/kallyas/chat-app/releases/tag/v1.0.0
[0.1.0]: https://github.com/kallyas/chat-app/releases/tag/v0.1.0
