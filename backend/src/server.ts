import 'module-alias/register';
import { createServer } from 'http';
import { config } from '@/config/environment';
import { logger } from '@/config/logger';
import { database } from '@/config/database';
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
    process.on('SIGTERM', gracefulShutdown);
    process.on('SIGINT', gracefulShutdown);

    function gracefulShutdown(signal: string) {
      logger.info(`Received ${signal}. Shutting down gracefully...`);
      
      httpServer.close(() => {
        logger.info('HTTP server closed');
        
        // Close database connection
        database.disconnect().then(() => {
          logger.info('Database connection closed');
          process.exit(0);
        }).catch((error) => {
          logger.error('Error closing database connection:', error);
          process.exit(1);
        });
      });

      // Force shutdown after 30 seconds
      setTimeout(() => {
        logger.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
      }, 30000);
    }

  } catch (error) {
    logger.error('Error starting server:', error);
    process.exit(1);
  }
};

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Start the server
startServer();