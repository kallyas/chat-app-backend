import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import {
  authenticateToken,
  optionalAuth,
  requireRoles,
  generateAccessToken,
  generateRefreshToken,
} from '@/middleware/auth';
import { User } from '@/models/User';
import { AuthRequest } from '@/types';
import { config } from '@/config/environment';

jest.mock('@/config/logger', () => ({
  logger: {
    error: jest.fn(),
    debug: jest.fn(),
  },
}));

describe('Auth Middleware', () => {
  let mockRequest: Partial<AuthRequest>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction;
  let testUser: any;

  beforeEach(async () => {
    testUser = await User.create({
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123',
    });

    mockRequest = {
      headers: {},
    };

    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };

    nextFunction = jest.fn();
  });

  describe('authenticateToken', () => {
    it('should authenticate with valid token', async () => {
      const token = generateAccessToken(testUser);
      mockRequest.headers = { authorization: `Bearer ${token}` };

      await authenticateToken(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(nextFunction).toHaveBeenCalled();
      expect(mockRequest.user).toBeDefined();
      expect(mockRequest.user?.email).toBe(testUser.email);
    });

    it('should return 401 if no token provided', async () => {
      await authenticateToken(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        message: 'Access token required',
      });
      expect(nextFunction).not.toHaveBeenCalled();
    });

    it('should return 401 for invalid token', async () => {
      mockRequest.headers = { authorization: 'Bearer invalid-token' };

      await authenticateToken(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        message: 'Invalid token',
      });
      expect(nextFunction).not.toHaveBeenCalled();
    });

    it('should return 401 for expired token', async () => {
      const expiredToken = jwt.sign(
        { id: testUser._id.toString() },
        config.jwt.secret,
        { expiresIn: '0s' }
      );
      mockRequest.headers = { authorization: `Bearer ${expiredToken}` };

      // Wait for token to expire
      await new Promise(resolve => setTimeout(resolve, 100));

      await authenticateToken(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        message: 'Token expired',
      });
    });

    it('should return 401 if user not found', async () => {
      const fakeUserId = '507f1f77bcf86cd799439011';
      const token = jwt.sign({ id: fakeUserId }, config.jwt.secret);
      mockRequest.headers = { authorization: `Bearer ${token}` };

      await authenticateToken(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        message: 'Invalid token - user not found',
      });
    });

    it('should return 401 for invalidated token version', async () => {
      const token = generateAccessToken(testUser);

      // Increment token version to invalidate existing tokens
      testUser.tokenVersion = (testUser.tokenVersion || 0) + 1;
      await testUser.save();

      mockRequest.headers = { authorization: `Bearer ${token}` };

      await authenticateToken(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        message: 'Token has been invalidated. Please login again.',
      });
    });
  });

  describe('optionalAuth', () => {
    it('should attach user if valid token provided', async () => {
      const token = generateAccessToken(testUser);
      mockRequest.headers = { authorization: `Bearer ${token}` };

      await optionalAuth(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(nextFunction).toHaveBeenCalled();
      expect(mockRequest.user).toBeDefined();
    });

    it('should continue without user if no token provided', async () => {
      await optionalAuth(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(nextFunction).toHaveBeenCalled();
      expect(mockRequest.user).toBeUndefined();
    });

    it('should continue without user if invalid token', async () => {
      mockRequest.headers = { authorization: 'Bearer invalid-token' };

      await optionalAuth(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(nextFunction).toHaveBeenCalled();
      expect(mockRequest.user).toBeUndefined();
    });
  });

  describe('requireRoles', () => {
    it('should continue if user is authenticated', () => {
      mockRequest.user = testUser;
      const middleware = requireRoles();

      middleware(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(nextFunction).toHaveBeenCalled();
    });

    it('should return 401 if user is not authenticated', () => {
      const middleware = requireRoles();

      middleware(
        mockRequest as AuthRequest,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        success: false,
        message: 'Authentication required',
      });
    });
  });

  describe('generateAccessToken', () => {
    it('should generate a valid access token', () => {
      const token = generateAccessToken(testUser);
      const decoded = jwt.verify(token, config.jwt.secret) as any;

      expect(decoded.id).toBe(testUser._id.toString());
      expect(decoded.email).toBe(testUser.email);
      expect(decoded.username).toBe(testUser.username);
    });
  });

  describe('generateRefreshToken', () => {
    it('should generate a valid refresh token', () => {
      const token = generateRefreshToken(testUser);
      const decoded = jwt.verify(token, config.jwt.secret) as any;

      expect(decoded.id).toBe(testUser._id.toString());
      expect(decoded.email).toBe(testUser.email);
      expect(decoded.username).toBe(testUser.username);
    });
  });
});
