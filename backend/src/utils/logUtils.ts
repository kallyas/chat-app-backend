import { logger } from '@/config/logger';
import { Request, Response } from 'express';

/**
 * Log HTTP requests with detailed information
 */
export const logHttpRequest = (req: Request, res: Response, responseTime?: number) => {
  const logData = {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    statusCode: res.statusCode,
    responseTime: responseTime ? `${responseTime}ms` : undefined,
    contentLength: res.get('Content-Length'),
    userId: (req as any).user?._id?.toString(),
  };

  // Log to access log
  logger.info('HTTP Request', logData);
};

/**
 * Log user actions for audit trail
 */
export const logUserAction = (
  userId: string,
  action: string,
  resource?: string,
  details?: Record<string, any>
) => {
  logger.info('User Action', {
    userId,
    action,
    resource,
    timestamp: new Date().toISOString(),
    ...details,
  });
};

/**
 * Log security events
 */
export const logSecurityEvent = (
  event: 'LOGIN_SUCCESS' | 'LOGIN_FAILURE' | 'UNAUTHORIZED_ACCESS' | 'TOKEN_VALIDATION_FAILED',
  details: Record<string, any>
) => {
  logger.warn('Security Event', {
    event,
    timestamp: new Date().toISOString(),
    ...details,
  });
};

/**
 * Log database operations for monitoring
 */
export const logDatabaseOperation = (
  operation: 'CREATE' | 'READ' | 'UPDATE' | 'DELETE',
  collection: string,
  documentId?: string,
  userId?: string,
  duration?: number
) => {
  logger.debug('Database Operation', {
    operation,
    collection,
    documentId,
    userId,
    duration: duration ? `${duration}ms` : undefined,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Log application errors with context
 */
export const logApplicationError = (
  error: Error,
  context: {
    userId?: string;
    action?: string;
    resource?: string;
    requestId?: string;
    additionalInfo?: Record<string, any>;
  }
) => {
  logger.error('Application Error', {
    message: error.message,
    stack: error.stack,
    name: error.name,
    timestamp: new Date().toISOString(),
    ...context,
  });
};

/**
 * Log performance metrics
 */
export const logPerformanceMetric = (
  metric: string,
  value: number,
  unit: 'ms' | 'bytes' | 'count' | 'percentage',
  context?: Record<string, any>
) => {
  logger.info('Performance Metric', {
    metric,
    value,
    unit,
    timestamp: new Date().toISOString(),
    ...context,
  });
};

/**
 * Create a child logger with consistent metadata
 */
export const createContextLogger = (context: Record<string, any>) => {
  return {
    info: (message: string, meta?: Record<string, any>) => 
      logger.info(message, { ...context, ...meta }),
    warn: (message: string, meta?: Record<string, any>) => 
      logger.warn(message, { ...context, ...meta }),
    error: (message: string, meta?: Record<string, any>) => 
      logger.error(message, { ...context, ...meta }),
    debug: (message: string, meta?: Record<string, any>) => 
      logger.debug(message, { ...context, ...meta }),
  };
};