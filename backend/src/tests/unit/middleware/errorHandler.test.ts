import { Request, Response, NextFunction } from 'express';
import mongoose from 'mongoose';
import {
  AppError,
  createError,
  globalErrorHandler,
  catchAsync,
  notFound,
} from '@/middleware/errorHandler';

jest.mock('@/config/logger', () => ({
  logger: {
    error: jest.fn(),
  },
}));

describe('Error Handler Middleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction;

  beforeEach(() => {
    mockRequest = {
      url: '/test',
      method: 'GET',
      ip: '127.0.0.1',
      originalUrl: '/api/test',
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
        message: 'Something went wrong!',
      });
    });

    it('should handle CastError from MongoDB', () => {
      process.env.NODE_ENV = 'production';
      const error: any = {
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
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: expect.stringContaining('Invalid'),
        })
      );
    });

    it('should handle duplicate key errors', () => {
      process.env.NODE_ENV = 'production';
      const error: any = {
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
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: expect.stringContaining('Duplicate'),
        })
      );
    });

    it('should handle JWT errors', () => {
      process.env.NODE_ENV = 'production';
      const error: any = {
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
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: expect.stringContaining('Invalid token'),
        })
      );
    });

    it('should handle token expired errors', () => {
      process.env.NODE_ENV = 'production';
      const error: any = {
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
      const asyncFn = async () => {
        throw new Error('Async error');
      };

      const wrappedFn = catchAsync(asyncFn);

      await wrappedFn(
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(nextFunction).toHaveBeenCalledWith(expect.any(Error));
    });

    it('should execute async function successfully', async () => {
      const asyncFn = async (req: Request, res: Response) => {
        res.status(200).json({ success: true });
      };

      const wrappedFn = catchAsync(asyncFn);

      await wrappedFn(
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith({ success: true });
    });
  });

  describe('notFound', () => {
    it('should create 404 error and call next', () => {
      notFound(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 404,
          message: expect.stringContaining('/api/test'),
        })
      );
    });
  });
});
