import { Request, Response, NextFunction } from 'express';
import { logHttpRequest } from '@/utils/logUtils';

/**
 * Middleware to log HTTP requests with response time
 */
export const requestLogger = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const startTime = Date.now();

  // Log request start
  const originalSend = res.send;

  res.send = function (data) {
    const responseTime = Date.now() - startTime;

    // Log the completed request
    logHttpRequest(req, res, responseTime);

    // Call original send method
    return originalSend.call(this, data);
  };

  next();
};

/**
 * Middleware to add request ID for tracking
 */
export const addRequestId = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Add request ID to request object
  (req as any).requestId = requestId;

  // Add request ID to response headers for debugging
  res.setHeader('X-Request-ID', requestId);

  next();
};
