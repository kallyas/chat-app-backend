import { NextFunction, Response } from 'express';
import { addRequestId, requestLogger } from '@/middleware/requestLogger';
import { AuthRequest } from '@/types';
import { logHttpRequest } from '@/utils/logUtils';

jest.mock('@/utils/logUtils', () => ({
  logHttpRequest: jest.fn(),
}));

describe('Request Logger Middleware', () => {
  let mockRequest: Partial<AuthRequest>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction;
  let eventHandlers: Record<string, () => void>;

  beforeEach(() => {
    eventHandlers = {};

    mockRequest = {
      method: 'GET',
      originalUrl: '/api/health',
      ip: '127.0.0.1',
      headers: {},
      get: jest.fn(),
    };

    mockResponse = {
      statusCode: 200,
      writableEnded: true,
      get: jest.fn(),
      on: jest.fn((event: string, handler: () => void) => {
        eventHandlers[event] = handler;
        return mockResponse as Response;
      }),
      setHeader: jest.fn(),
    };

    nextFunction = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should create a request ID when one is not provided', () => {
    addRequestId(
      mockRequest as AuthRequest,
      mockResponse as Response,
      nextFunction
    );

    expect(mockRequest.requestId).toBeDefined();
    expect(mockResponse.setHeader).toHaveBeenCalledWith(
      'X-Request-ID',
      mockRequest.requestId
    );
    expect(nextFunction).toHaveBeenCalled();
  });

  it('should reuse a valid incoming request ID', () => {
    mockRequest.headers = {
      'x-request-id': 'trace-123',
    };

    addRequestId(
      mockRequest as AuthRequest,
      mockResponse as Response,
      nextFunction
    );

    expect(mockRequest.requestId).toBe('trace-123');
    expect(mockResponse.setHeader).toHaveBeenCalledWith(
      'X-Request-ID',
      'trace-123'
    );
  });

  it('should log requests on response finish', () => {
    requestLogger(mockRequest as AuthRequest, mockResponse as Response, nextFunction);

    eventHandlers.finish();

    expect(logHttpRequest).toHaveBeenCalledWith(
      mockRequest,
      mockResponse,
      expect.any(Number),
      true
    );
  });

  it('should mark closed unfinished responses as incomplete', () => {
    Object.defineProperty(mockResponse, 'writableEnded', {
      value: false,
      configurable: true,
    });

    requestLogger(mockRequest as AuthRequest, mockResponse as Response, nextFunction);

    eventHandlers.close();

    expect(logHttpRequest).toHaveBeenCalledWith(
      mockRequest,
      mockResponse,
      expect.any(Number),
      false
    );
  });
});
