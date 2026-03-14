import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config, isAllowedCorsOrigin } from '@/config/environment';
import {
  globalErrorHandler,
  notFound,
  generalLimiter,
  requestLogger,
  addRequestId,
} from '@/middleware';
import routes from '@/routes';

export const createApp = () => {
  const app = express();
  const corsOptions: cors.CorsOptions = {
    origin(origin, callback) {
      if (isAllowedCorsOrigin(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error(`CORS origin not allowed: ${origin}`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  };

  // Request ID middleware (should be first)
  app.use(addRequestId);

  // Security middleware
  app.use(helmet());

  // CORS configuration
  app.use(cors(corsOptions));

  // Rate limiting
  app.use(generalLimiter);

  // Body parsing middleware
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Enhanced request logging middleware
  app.use(requestLogger);

  // API routes
  app.use('/api', routes);

  // Root endpoint
  app.get('/', (req, res) => {
    res.json({
      success: true,
      message: 'Chat Application API',
      version: '1.0.0',
      documentation: '/api/health',
    });
  });

  // Handle 404 routes
  app.use(notFound);

  // Global error handler (must be last)
  app.use(globalErrorHandler);

  return app;
};
