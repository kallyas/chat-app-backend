import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from '@/config/environment';
import { logger } from '@/config/logger';
import { globalErrorHandler, notFound, generalLimiter } from '@/middleware';
import routes from '@/routes';

export const createApp = () => {
  const app = express();

  // Security middleware
  app.use(helmet());

  // CORS configuration
  app.use(cors({
    origin: config.cors.origins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }));

  // Rate limiting
  app.use(generalLimiter);

  // Body parsing middleware
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Request logging middleware
  app.use((req, res, next) => {
    logger.info(`${req.method} ${req.originalUrl}`, {
      ip: req.ip,
      userAgent: req.get('User-Agent'),
    });
    next();
  });

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