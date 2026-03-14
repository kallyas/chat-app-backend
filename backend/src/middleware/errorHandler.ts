import { Request, Response, NextFunction } from 'express';
import { logger } from '@/config/logger';
import mongoose from 'mongoose';
import { AuthRequest } from '@/types';

type DuplicateKeyError = {
  code: number;
  keyValue: Record<string, unknown>;
};

type CastErrorLike = {
  name: 'CastError';
  path: string;
  value: unknown;
};

type ErrorWithStatusCode = Error & {
  statusCode?: number;
};

export class AppError extends Error {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export const createError = (message: string, statusCode: number) => {
  return new AppError(message, statusCode);
};

const handleCastErrorDB = (err: Pick<mongoose.Error.CastError, 'path' | 'value'>) => {
  const message = `Invalid ${err.path}: ${err.value}`;
  return new AppError(message, 400);
};

const handleDuplicateFieldsDB = (err: DuplicateKeyError) => {
  const field = Object.keys(err.keyValue)[0];
  const value = String(err.keyValue[field]);
  const message = `Duplicate field value: ${value}. Please use another value for ${field}`;
  return new AppError(message, 400);
};

const handleValidationErrorDB = (err: mongoose.Error.ValidationError) => {
  const errors = Object.values(err.errors).map(el => el.message);
  const message = `Invalid input data: ${errors.join('. ')}`;
  return new AppError(message, 400);
};

const handleJWTError = () =>
  new AppError('Invalid token. Please log in again!', 401);

const handleJWTExpiredError = () =>
  new AppError('Your token has expired! Please log in again.', 401);

const sendErrorDev = (err: AppError, req: AuthRequest, res: Response) => {
  res.status(err.statusCode).json({
    success: false,
    requestId: req.requestId,
    error: err,
    message: err.message,
    stack: err.stack,
  });
};

const sendErrorProd = (err: AppError, req: AuthRequest, res: Response) => {
  if (err.isOperational) {
    res.status(err.statusCode).json({
      success: false,
      requestId: req.requestId,
      message: err.message,
    });
  } else {
    logger.error('ERROR:', err);

    res.status(500).json({
      success: false,
      requestId: req.requestId,
      message: 'Something went wrong!',
    });
  }
};

export const globalErrorHandler = (
  err: unknown,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  void next;

  const request = req as AuthRequest;
  const baseError =
    err instanceof Error ? err : new Error('Unexpected non-error thrown');
  const errorName = getErrorName(err);
  const statusCode =
    typeof (err as ErrorWithStatusCode | undefined)?.statusCode === 'number'
      ? ((err as ErrorWithStatusCode).statusCode as number)
      : 500;
  const normalizedError =
    err instanceof AppError ? err : new AppError(baseError.message, statusCode);

  if (!(err instanceof AppError)) {
    normalizedError.isOperational = false;
  }

  logger.error('Global error handler:', {
    message: baseError.message,
    stack: baseError.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    requestId: request.requestId,
  });

  if (process.env.NODE_ENV === 'development') {
    sendErrorDev(normalizedError, request, res);
  } else {
    let responseError = normalizedError;

    if (err instanceof mongoose.Error.CastError || isCastErrorLike(err)) {
      responseError = handleCastErrorDB(err);
    } else if (isDuplicateKeyError(err)) {
      responseError = handleDuplicateFieldsDB(err);
    } else if (err instanceof mongoose.Error.ValidationError) {
      responseError = handleValidationErrorDB(err);
    } else if (errorName === 'JsonWebTokenError') {
      responseError = handleJWTError();
    } else if (errorName === 'TokenExpiredError') {
      responseError = handleJWTExpiredError();
    }

    sendErrorProd(responseError, request, res);
  }
};

export const catchAsync = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    void fn(req, res, next).catch(next);
  };
};

export const notFound = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const error = new AppError(`Not found - ${req.originalUrl}`, 404);
  next(error);
};

const isDuplicateKeyError = (err: unknown): err is DuplicateKeyError => {
  if (typeof err !== 'object' || err === null || !('code' in err)) {
    return false;
  }

  const candidate = err as Partial<DuplicateKeyError>;
  return candidate.code === 11000 && typeof candidate.keyValue === 'object';
};

const isCastErrorLike = (err: unknown): err is CastErrorLike => {
  if (typeof err !== 'object' || err === null) {
    return false;
  }

  const candidate = err as Partial<CastErrorLike>;
  return (
    candidate.name === 'CastError' &&
    typeof candidate.path === 'string' &&
    'value' in candidate
  );
};

const getErrorName = (err: unknown): string | undefined => {
  if (err instanceof Error) {
    return err.name;
  }

  if (typeof err === 'object' && err !== null && 'name' in err) {
    const candidate = err as { name?: unknown };
    return typeof candidate.name === 'string' ? candidate.name : undefined;
  }

  return undefined;
};
