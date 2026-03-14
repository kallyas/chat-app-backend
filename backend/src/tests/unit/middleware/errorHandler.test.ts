import { Request, Response, NextFunction } from 'express';
import {
  AppError,
  createError,
  globalErrorHandler,
  catchAsync,
  notFound,
} from '@/middleware/errorHandler';
import { AuthRequest } from '@/types';

jest.mock('@/config/logger', () => ({
  logger: {
    error: jest.fn(),
  },
}));

describe('Error Handler Middleware', () => {
  let mockRequest: Partial<AuthRequest>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction;

  const getJsonPayload = <T,>() => {
    const mockJson = mockResponse.json as jest.Mock;
    const calls = mockJson.mock.calls as unknown[][];
    return calls[0][0] as T;
  };

  const getNextError = () => {
    const mockNext = nextFunction as jest.Mock;
    const calls = mockNext.mock.calls as unknown[][];
    return calls[0][0] as AppError;
  };

  beforeEach(() => {
    mockRequest = {
      url: '/test',
      method: 'GET',
      ip: '127.0.0.1',
      originalUrl: '/api/test',
      requestId: 'req-test-id',
    };

    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };

    nextFunction = jest.fn();
  });

  describe('AppError', () => {
    it('should create operational error with status code', () => {
      const error = new AppError('Test error', 400);

      expect(error.message).toBe('Test error');
      expect(error.statusCode).toBe(400);
      expect(error.isOperational).toBe(true);
      expect(error.stack).toBeDefined();
    });
  });

  describe('createError', () => {
    it('should create and return AppError instance', () => {
      const error = createError('Not found', 404);

      expect(error).toBeInstanceOf(AppError);
      expect(error.message).toBe('Not found');
      expect(error.statusCode).toBe(404);
    });
  });

  describe('globalErrorHandler', () => {
    it('should handle operational errors in development', () => {
      process.env.NODE_ENV = 'development';
      const error = new AppError('Test error', 400);

      globalErrorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        requestId: 'req-test-id',
        error,
        message: 'Test error',
        stack: error.stack,
      });
    });

    it('should handle operational errors in production', () => {
      process.env.NODE_ENV = 'production';
      const error = new AppError('Test error', 400);

      globalErrorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        requestId: 'req-test-id',
        message: 'Test error',
      });
    });

    it('should handle non-operational errors in production', () => {
      process.env.NODE_ENV = 'production';
      const error = new Error('Internal error');

      globalErrorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        requestId: 'req-test-id',
        message: 'Something went wrong!',
      });
    });

    it('should handle CastError from MongoDB', () => {
      process.env.NODE_ENV = 'production';
      const error = {
        name: 'CastError',
        path: '_id',
        value: 'invalid-id',
        message: 'Cast to ObjectId failed',
      };

      globalErrorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      const payload = getJsonPayload<{
        success: boolean;
        message: string;
      }>();
      expect(payload.success).toBe(false);
      expect(payload.message).toContain('Invalid');
    });

    it('should handle duplicate key errors', () => {
      process.env.NODE_ENV = 'production';
      const error = {
        code: 11000,
        keyValue: { email: 'test@example.com' },
        message: 'Duplicate key error',
      };

      globalErrorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      const payload = getJsonPayload<{
        success: boolean;
        message: string;
      }>();
      expect(payload.success).toBe(false);
      expect(payload.message).toContain('Duplicate');
    });

    it('should handle JWT errors', () => {
      process.env.NODE_ENV = 'production';
      const error = {
        name: 'JsonWebTokenError',
        message: 'Invalid token',
      };

      globalErrorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      const payload = getJsonPayload<{
        success: boolean;
        message: string;
      }>();
      expect(payload.success).toBe(false);
      expect(payload.message).toContain('Invalid token');
    });

    it('should handle token expired errors', () => {
      process.env.NODE_ENV = 'production';
      const error = {
        name: 'TokenExpiredError',
        message: 'Token expired',
      };

      globalErrorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });
  });

  describe('catchAsync', () => {
    it('should call next with error if async function throws', async () => {
      const asyncFn = () => Promise.reject(new Error('Async error'));

      const wrappedFn = catchAsync(asyncFn);

      wrappedFn(mockRequest as Request, mockResponse as Response, nextFunction);

      await new Promise(resolve => setImmediate(resolve));

      expect(nextFunction).toHaveBeenCalledWith(expect.any(Error));
    });

    it('should execute async function successfully', async () => {
      const asyncFn = (req: Request, res: Response) => {
        res.status(200).json({ success: true });
        return Promise.resolve();
      };

      const wrappedFn = catchAsync(asyncFn);

      wrappedFn(mockRequest as Request, mockResponse as Response, nextFunction);

      await new Promise(resolve => setImmediate(resolve));

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith({ success: true });
    });
  });

  describe('notFound', () => {
    it('should create 404 error and call next', () => {
      notFound(mockRequest as Request, mockResponse as Response, nextFunction);

      const error = getNextError();
      expect(error.statusCode).toBe(404);
      expect(error.message).toContain('/api/test');
    });
  });
});
