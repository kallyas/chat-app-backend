import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import { authenticateSocket, AuthenticatedSocket } from './socketAuth';
import { setupChatEvents } from './chatEvents';
import { config } from '@/config/environment';
import { logger } from '@/config/logger';

export const setupSocketIO = (httpServer: HttpServer): Server => {
  const io = new Server(httpServer, {
    cors: {
      origin: config.cors.origins,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // Authentication middleware
  io.use(authenticateSocket);

  // Handle connections
  io.on('connection', (socket: AuthenticatedSocket) => {
    logger.info(`User connected: ${socket.username} (${socket.id})`);

    // Set up chat event handlers
    setupChatEvents(io, socket);

    // Send welcome message
    socket.emit('connected', {
      message: 'Welcome to the chat!',
      userId: socket.userId,
      username: socket.username,
      timestamp: new Date(),
    });

    // Join user to their personal room for direct notifications
    if (socket.userId) {
      socket.join(`user_${socket.userId}`);
    }
  });

  // Handle server errors
  io.on('error', (error) => {
    logger.error('Socket.IO server error:', error);
  });

  logger.info('Socket.IO server initialized');

  return io;
};

export * from './socketAuth';
export * from './chatEvents';