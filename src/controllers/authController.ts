import { Request, Response } from 'express';
import { AuthService } from '@/services';
import { catchAsync, AppError, generateAccessToken, generateRefreshToken, AuthRequest } from '@/middleware';
import { registerSchema, loginSchema, resetPasswordSchema } from '@/utils';
import { logger } from '@/config/logger';

export const register = catchAsync(async (req: Request, res: Response) => {
  const { error, value } = registerSchema.validate(req.body);
  
  if (error) {
    throw new AppError(error.details[0].message, 400);
  }

  const user = await AuthService.registerUser(value);
  
  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);

  res.status(201).json({
    success: true,
    message: 'User registered successfully',
    data: {
      user,
      tokens: {
        access: accessToken,
        refresh: refreshToken,
      },
    },
  });
});

export const login = catchAsync(async (req: Request, res: Response) => {
  const { error, value } = loginSchema.validate(req.body);
  
  if (error) {
    throw new AppError(error.details[0].message, 400);
  }

  const user = await AuthService.loginUser(value);
  
  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);

  res.status(200).json({
    success: true,
    message: 'Login successful',
    data: {
      user,
      tokens: {
        access: accessToken,
        refresh: refreshToken,
      },
    },
  });
});

export const logout = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  await AuthService.logoutUser(req.user._id.toString());

  res.status(200).json({
    success: true,
    message: 'Logout successful',
  });
});

export const getMe = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  res.status(200).json({
    success: true,
    data: {
      user: req.user,
    },
  });
});

export const updateProfile = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const user = await AuthService.updateUserProfile(req.user._id.toString(), req.body);

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: {
      user,
    },
  });
});

export const initiatePasswordReset = catchAsync(async (req: Request, res: Response) => {
  const { error, value } = resetPasswordSchema.validate(req.body);
  
  if (error) {
    throw new AppError(error.details[0].message, 400);
  }

  const resetToken = await AuthService.initiatePasswordReset(value.email);

  // In production, you would send this token via email
  // For demo purposes, we're returning it in the response
  res.status(200).json({
    success: true,
    message: 'Password reset token generated. In production, this would be sent via email.',
    data: {
      resetToken, // Don't return this in production
    },
  });
});

export const resetPassword = catchAsync(async (req: Request, res: Response) => {
  const { token } = req.params;
  const { password } = req.body;

  if (!password) {
    throw new AppError('Password is required', 400);
  }

  if (password.length < 6) {
    throw new AppError('Password must be at least 6 characters', 400);
  }

  await AuthService.resetPassword(token, password);

  res.status(200).json({
    success: true,
    message: 'Password reset successfully',
  });
});

export const refreshToken = catchAsync(async (req: Request, res: Response) => {
  const { refreshToken: token } = req.body;

  if (!token) {
    throw new AppError('Refresh token is required', 400);
  }

  // In a full implementation, you would validate the refresh token
  // and generate new access/refresh tokens
  // For simplicity, we're not implementing full refresh token logic here
  
  throw new AppError('Refresh token functionality not implemented', 501);
});

export const searchUsers = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { query, type = 'both' } = req.query;

  if (!query || typeof query !== 'string') {
    throw new AppError('Search query is required', 400);
  }

  if (query.length < 1) {
    throw new AppError('Search query must be at least 1 character', 400);
  }

  const users = await AuthService.searchUsers(
    query,
    req.user._id.toString(),
    type as 'username' | 'email' | 'both'
  );

  res.status(200).json({
    success: true,
    data: {
      users,
      count: users.length,
    },
  });
});

export const getOnlineUsers = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const users = await AuthService.getOnlineUsers();

  res.status(200).json({
    success: true,
    data: {
      users,
      count: users.length,
    },
  });
});