import { Request, Response, NextFunction } from 'express';
import { logHttpRequest } from '@/utils/logUtils';
import { randomUUID } from 'crypto';
import { AuthRequest } from '@/types';

const REQUEST_ID_HEADER = 'x-request-id';

const sanitizeRequestId = (value?: string | string[]): string | null => {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed || trimmed.length > 128) {
    return null;
  }

  return /^[a-zA-Z0-9-_.]+$/.test(trimmed) ? trimmed : null;
};

/**
 * Middleware to log HTTP requests with response time
 */
export const requestLogger = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const startTime = Date.now();
  let logged = false;

  const logRequest = (completed: boolean) => {
    if (logged) {
      return;
    }

    logged = true;
    const responseTime = Date.now() - startTime;
    logHttpRequest(req as AuthRequest, res, responseTime, completed);
  };

  res.on('finish', () => {
    logRequest(true);
  });

  res.on('close', () => {
    logRequest(res.writableEnded);
  });

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
  const requestId =
    sanitizeRequestId(req.headers[REQUEST_ID_HEADER]) ?? randomUUID();

  (req as AuthRequest).requestId = requestId;

  res.setHeader('X-Request-ID', requestId);

  next();
};
