# Chat App

[![Tests](https://github.com/kallyas/chat-app-backend/actions/workflows/ci.yml/badge.svg)](https://github.com/kallyas/chat-app-backend/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/kallyas/chat-app-backend/graph/badge.svg?token=81KYBVzPSw)](https://codecov.io/gh/kallyas/chat-app-backend)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Chat App is a monorepo for a real-time messaging platform. It includes a TypeScript backend built with Express, MongoDB, and Socket.IO, and a Flutter mobile client.

## Repository Structure

```text
chat-app/
├── backend/   Node.js, TypeScript, Express, MongoDB, Socket.IO
├── mobile/    Flutter mobile client
└── .github/   CI workflows
```

## Components

### Backend

The backend provides:

- JWT-based authentication
- Real-time messaging with Socket.IO
- Private and group chat rooms
- Message read receipts and typing indicators
- Input validation, rate limiting, and structured logging

Backend documentation is available in [backend/README.md](/Users/tum/programming/personal/chat-app/backend/README.md).

### Mobile

The mobile application is built with Flutter and connects to the backend API and Socket.IO server.

Mobile documentation is available in [mobile/README.md](/Users/tum/programming/personal/chat-app/mobile/README.md).

## Quick Start

### Prerequisites

- Node.js 18 or later
- MongoDB 5.0 or later
- Yarn
- Flutter SDK 3.0 or later for mobile development

### Run the Backend

```bash
cd backend
yarn install
cp .env.example .env
yarn dev
```

The backend runs on `http://localhost:3000` by default.

### Run the Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

Before running the mobile app, update the API and socket endpoints in `mobile/lib/config/api_config.dart` if needed.

## Backend Environment

The backend uses `backend/.env`. Start from [`backend/.env.example`](/Users/tum/programming/personal/chat-app/backend/.env.example).

Common variables:

```env
MONGODB_URI=mongodb://localhost:27017/chatapp
JWT_SECRET=your-secret
JWT_EXPIRE=7d
PORT=3000
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

## Common Commands

Backend:

```bash
cd backend
yarn dev
yarn build
yarn start
yarn test
yarn test:coverage
yarn lint
yarn format
```

Mobile:

```bash
cd mobile
flutter test
flutter build apk --release
flutter build ios --release
```

## Docker

The backend includes a Dockerfile:

```bash
cd backend
docker build -t chat-app .
docker run -p 3000:3000 --env-file .env chat-app
```

## License

This project is licensed under the MIT License. See [LICENSE](/Users/tum/programming/personal/chat-app/LICENSE).
