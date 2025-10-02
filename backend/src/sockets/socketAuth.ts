import { Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { User } from '@/models';
import { config } from '@/config/environment';
import { logger } from '@/config/logger';
import { JWTPayload } from '@/types';

export interface AuthenticatedSocket extends Socket {
  userId?: string;
  username?: string;
}

export const authenticateSocket = async (
  socket: AuthenticatedSocket,
  next: (err?: Error) => void
) => {
  try {
    const token =
      socket.handshake.auth.token || socket.handshake.headers.authorization;

    if (!token) {
      return next(new Error('Authentication token required'));
    }

    // Remove 'Bearer ' prefix if present
    const cleanToken = token.replace('Bearer ', '');

    const decoded = jwt.verify(cleanToken, config.jwt.secret) as JWTPayload;

    const user = await User.findById(decoded.id).select('-password');

    if (!user) {
      return next(new Error('Invalid token - user not found'));
    }

    // Validate token version
    if (
      decoded.tokenVersion !== undefined &&
      decoded.tokenVersion !== user.tokenVersion
    ) {
      return next(new Error('Token has been invalidated. Please login again.'));
    }

    // Attach user info to socket
    socket.userId = user._id.toString();
    socket.username = user.username;

    // Increment socket count and update online status atomically
    await User.findByIdAndUpdate(user._id, {
      $inc: { activeSocketCount: 1 },
      isOnline: true,
      lastSeen: new Date(),
    });

    logger.info(`Socket authenticated: ${user.username} (${socket.id})`);

    next();
  } catch (error) {
    logger.error('Socket authentication error:', error);

    if (error instanceof jwt.TokenExpiredError) {
      return next(new Error('Token expired'));
    }

    if (error instanceof jwt.JsonWebTokenError) {
      return next(new Error('Invalid token'));
    }

    return next(new Error('Authentication failed'));
  }
};
