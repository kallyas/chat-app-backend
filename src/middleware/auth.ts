import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { User, IUser } from '@/models';
import { config } from '@/config/environment';
import { logger } from '@/config/logger';

export interface AuthRequest extends Request {
  user?: IUser;
}

export interface JWTPayload {
  id: string;
  email: string;
  username: string;
  iat?: number;
  exp?: number;
}

export const authenticateToken = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      res.status(401).json({
        success: false,
        message: 'Access token required',
      });
      return;
    }

    const decoded = jwt.verify(token, config.jwt.secret) as JWTPayload;

    const user = await User.findById(decoded.id).select('-password');
    
    if (!user) {
      res.status(401).json({
        success: false,
        message: 'Invalid token - user not found',
      });
      return;
    }

    req.user = user;
    next();
  } catch (error) {
    logger.error('Authentication error:', error);

    if (error instanceof jwt.TokenExpiredError) {
      res.status(401).json({
        success: false,
        message: 'Token expired',
      });
      return;
    }

    if (error instanceof jwt.JsonWebTokenError) {
      res.status(401).json({
        success: false,
        message: 'Invalid token',
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: 'Authentication failed',
    });
  }
};

export const optionalAuth = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return next();
    }

    const decoded = jwt.verify(token, config.jwt.secret) as JWTPayload;
    const user = await User.findById(decoded.id).select('-password');
    
    if (user) {
      req.user = user;
    }

    next();
  } catch (error) {
    logger.debug('Optional auth failed:', error);
    next();
  }
};

export const requireRoles = (roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
      return;
    }

    next();
  };
};

export const generateAccessToken = (user: IUser): string => {
  const payload: JWTPayload = {
    id: user._id.toString(),
    email: user.email,
    username: user.username,
  };

  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.accessExpirationMinutes,
  } as jwt.SignOptions);
};

export const generateRefreshToken = (user: IUser): string => {
  const payload: JWTPayload = {
    id: user._id.toString(),
    email: user.email,
    username: user.username,
  };

  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: '30d',
  } as jwt.SignOptions);
};