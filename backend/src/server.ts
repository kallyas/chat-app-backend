import 'module-alias/register';
import { createServer } from 'http';
import { config } from '@/config/environment';
import { logger } from '@/config/logger';
import { database } from '@/config/database';
import { runtimeState } from '@/config/runtime';
import { createApp } from './app';
import { setupSocketIO } from '@/sockets';

const startServer = async () => {
  try {
    // Connect to database
    await database.connect();

    // Create Express app
    const app = createApp();

    // Create HTTP server
    const httpServer = createServer(app);

    // Set up Socket.IO
    const io = setupSocketIO(httpServer);

    // Start server
    const PORT = config.port || 3000;

    httpServer.listen(PORT, () => {
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`📍 Environment: ${config.env}`);
      logger.info(`🔗 API URL: http://localhost:${PORT}/api`);
      logger.info(`🔌 Socket.IO URL: http://localhost:${PORT}`);
    });

    // Graceful shutdown
    const gracefulShutdown = (signal: string): void => {
      if (runtimeState.isShuttingDown()) {
        logger.warn('Graceful shutdown already in progress');
        return;
      }

      runtimeState.markShuttingDown();
      logger.info(`Received ${signal}. Shutting down gracefully...`);

      io.disconnectSockets();
      logger.info('Disconnecting all Socket.IO clients...');

      void io.close(() => {
        logger.info('Socket.IO server closed');
      });

      const forceShutdownTimer = setTimeout(() => {
        logger.error(
          'Could not close connections in time, forcefully shutting down'
        );
        process.exit(1);
      }, config.server.shutdownTimeoutMs);

      httpServer.close(() => {
        logger.info('HTTP server closed');
        void database
          .disconnect()
          .then(() => {
            logger.info('Database connection closed');
            clearTimeout(forceShutdownTimer);
            process.exit(0);
          })
          .catch(error => {
            logger.error('Error closing database connection:', error);
            clearTimeout(forceShutdownTimer);
            process.exit(1);
          });
      });
    };

    process.once('SIGTERM', () => {
      gracefulShutdown('SIGTERM');
    });
    process.once('SIGINT', () => {
      gracefulShutdown('SIGINT');
    });
  } catch (error) {
    logger.error('Error starting server:', error);
    process.exit(1);
  }
};

// Handle uncaught exceptions
process.on('uncaughtException', error => {
  logger.error('Uncaught Exception:', error);
  runtimeState.markShuttingDown();
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  runtimeState.markShuttingDown();
  process.exit(1);
});

// Start the server
void startServer();
