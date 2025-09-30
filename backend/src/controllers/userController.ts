import { Request, Response } from 'express';
import { AuthService } from '@/services';
import { catchAsync, AppError } from '@/middleware';
import { updateUserSchema, searchSchema } from '@/utils';
import type { AuthRequest } from '@/types';

export const getProfile = catchAsync(async (req: AuthRequest, res: Response): Promise<void> => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  await Promise.resolve(); // Satisfy the await requirement

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

  const validation = updateUserSchema.validate(req.body);
  
  if (validation.error) {
    throw new AppError(validation.error.details[0].message, 400);
  }

  const user = await AuthService.updateUserProfile(req.user._id.toString(), validation.value as { username?: string; profilePic?: string; password?: string });

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: {
      user,
    },
  });
});

export const searchUsers = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const validation = searchSchema.validate(req.query);
  
  if (validation.error) {
    throw new AppError(validation.error.details[0].message, 400);
  }

  const users = await AuthService.searchUsers(
    (validation.value as { query: string }).query,
    req.user._id.toString(),
    (validation.value as { type: string }).type as 'username' | 'email' | 'both'
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

  // Filter out the current user from the online users list
  const filteredUsers = users.filter(user => 
    req.user && !user._id.equals(req.user._id)
  );

  res.status(200).json({
    success: true,
    data: {
      users: filteredUsers,
      count: filteredUsers.length,
    },
  });
});

export const getUserById = catchAsync(async (req: Request, res: Response) => {
  const { userId } = req.params;

  if (!userId) {
    throw new AppError('User ID is required', 400);
  }

  const user = await AuthService.getUserById(userId);

  if (!user) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    success: true,
    data: {
      user,
    },
  });
});

export const updateOnlineStatus = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { isOnline } = req.body as { isOnline: boolean };

  if (typeof isOnline !== 'boolean') {
    throw new AppError('isOnline must be a boolean', 400);
  }

  await AuthService.updateUserOnlineStatus(req.user._id.toString(), isOnline);

  res.status(200).json({
    success: true,
    message: 'Online status updated successfully',
  });
});