import { Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { authenticateSocket, AuthenticatedSocket } from '@/sockets/socketAuth';
import { User } from '@/models/User';
import { config } from '@/config/environment';

jest.mock('@/config/logger', () => ({
  logger: {
    info: jest.fn(),
    error: jest.fn(),
  },
}));

describe('Socket Authentication', () => {
  let testUser: any;
  let mockSocket: Partial<AuthenticatedSocket>;
  let mockNext: jest.Mock;

  beforeEach(async () => {
    testUser = await User.create({
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123',
    });

    mockSocket = {
      id: 'socket-123',
      handshake: {
        auth: {},
        headers: {},
      } as any,
    };

    mockNext = jest.fn();
  });

  it('should authenticate socket with valid token in auth object', async () => {
    const token = jwt.sign(
      {
        id: testUser._id.toString(),
        email: testUser.email,
        username: testUser.username,
        tokenVersion: testUser.tokenVersion,
      },
      config.jwt.secret
    );

    mockSocket.handshake!.auth = { token };

    await authenticateSocket(
      mockSocket as AuthenticatedSocket,
      mockNext
    );

    expect(mockNext).toHaveBeenCalledWith();
    expect(mockSocket.userId).toBe(testUser._id.toString());
    expect(mockSocket.username).toBe(testUser.username);

    // Verify user was updated
    const updatedUser = await User.findById(testUser._id);
    expect(updatedUser?.isOnline).toBe(true);
    expect(updatedUser?.activeSocketCount).toBe(1);
  });

  it('should authenticate socket with valid token in headers', async () => {
    const token = jwt.sign(
      {
        id: testUser._id.toString(),
        email: testUser.email,
        username: testUser.username,
        tokenVersion: testUser.tokenVersion,
      },
      config.jwt.secret
    );

    mockSocket.handshake!.headers = { authorization: `Bearer ${token}` };

    await authenticateSocket(
      mockSocket as AuthenticatedSocket,
      mockNext
    );

    expect(mockNext).toHaveBeenCalledWith();
    expect(mockSocket.userId).toBe(testUser._id.toString());
  });

  it('should reject connection without token', async () => {
    await authenticateSocket(
      mockSocket as AuthenticatedSocket,
      mockNext
    );

    expect(mockNext).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Authentication token required',
      })
    );
  });

  it('should reject connection with invalid token', async () => {
    mockSocket.handshake!.auth = { token: 'invalid-token' };

    await authenticateSocket(
      mockSocket as AuthenticatedSocket,
      mockNext
    );

    expect(mockNext).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Invalid token',
      })
    );
  });

  it('should reject connection with expired token', async () => {
    const expiredToken = jwt.sign(
      {
        id: testUser._id.toString(),
        email: testUser.email,
        username: testUser.username,
      },
      config.jwt.secret,
      { expiresIn: '0s' }
    );

    mockSocket.handshake!.auth = { token: expiredToken };

    // Wait for token to expire
    await new Promise(resolve => setTimeout(resolve, 100));

    await authenticateSocket(
      mockSocket as AuthenticatedSocket,
      mockNext
    );

    expect(mockNext).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Token expired',
      })
    );
  });

  it('should reject connection if user not found', async () => {
    const fakeUserId = '507f1f77bcf86cd799439011';
    const token = jwt.sign(
      { id: fakeUserId, email: 'fake@example.com', username: 'fakeuser' },
      config.jwt.secret
    );

    mockSocket.handshake!.auth = { token };

    await authenticateSocket(
      mockSocket as AuthenticatedSocket,
      mockNext
    );

    expect(mockNext).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Invalid token - user not found',
      })
    );
  });

  it('should reject connection with invalidated token version', async () => {
    const token = jwt.sign(
      {
        id: testUser._id.toString(),
        email: testUser.email,
        username: testUser.username,
        tokenVersion: 0,
      },
      config.jwt.secret
    );

    // Increment token version to invalidate existing tokens
    testUser.tokenVersion = 1;
    await testUser.save();

    mockSocket.handshake!.auth = { token };

    await authenticateSocket(
      mockSocket as AuthenticatedSocket,
      mockNext
    );

    expect(mockNext).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Token has been invalidated. Please login again.',
      })
    );
  });
});
