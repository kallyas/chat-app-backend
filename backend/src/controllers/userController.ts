import { Request, Response } from 'express';
import { AuthService } from '@/services';
import { catchAsync, AppError } from '@/middleware';
import { updateUserSchema, searchSchema } from '@/utils';
import type { AuthRequest } from '@/types';

export const getProfile = catchAsync(
  async (req: AuthRequest, res: Response): Promise<void> => {
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
  }
);

export const updateProfile = catchAsync(
  async (req: AuthRequest, res: Response) => {
    if (!req.user) {
      throw new AppError('User not authenticated', 401);
    }

    const validation = updateUserSchema.validate(req.body);

    if (validation.error) {
      throw new AppError(validation.error.details[0].message, 400);
    }

    const user = await AuthService.updateUserProfile(
      req.user._id.toString(),
      validation.value as {
        username?: string;
        profilePic?: string;
        password?: string;
      }
    );

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user,
      },
    });
  }
);

export const searchUsers = catchAsync(
  async (req: AuthRequest, res: Response) => {
    if (!req.user) {
      throw new AppError('User not authenticated', 401);
    }

    const { query, type = 'both', page = '1', limit = '20' } = req.query;

    if (!query || typeof query !== 'string') {
      throw new AppError('Search query is required', 400);
    }

    if (query.length < 1) {
      throw new AppError('Search query must be at least 1 character', 400);
    }

    // Parse and validate pagination parameters
    const pageNum = parseInt(page as string) || 1;
    const limitNum = Math.min(parseInt(limit as string) || 20, 100); // Max 100 per page

    if (pageNum < 1) {
      throw new AppError('Page must be greater than 0', 400);
    }

    if (limitNum < 1) {
      throw new AppError('Limit must be greater than 0', 400);
    }

    const result = await AuthService.searchUsers(
      query,
      req.user._id.toString(),
      type as 'username' | 'email' | 'both',
      pageNum,
      limitNum
    );

    res.status(200).json({
      success: true,
      data: {
        users: result.users,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total: result.total,
          totalPages: result.totalPages,
          hasNext: result.hasNext,
          hasPrev: result.hasPrev,
        },
      },
    });
  }
);

export const getOnlineUsers = catchAsync(
  async (req: AuthRequest, res: Response) => {
    if (!req.user) {
      throw new AppError('User not authenticated', 401);
    }

    const { page = '1', limit = '20' } = req.query;

    // Parse and validate pagination parameters
    const pageNum = parseInt(page as string) || 1;
    const limitNum = Math.min(parseInt(limit as string) || 20, 100); // Max 100 per page

    if (pageNum < 1) {
      throw new AppError('Page must be greater than 0', 400);
    }

    if (limitNum < 1) {
      throw new AppError('Limit must be greater than 0', 400);
    }

    const result = await AuthService.getOnlineUsers(pageNum, limitNum);

    // Filter out the current user from the online users list
    const filteredUsers = result.users.filter(
      user => req.user && !user._id.equals(req.user._id)
    );

    res.status(200).json({
      success: true,
      data: {
        users: filteredUsers,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total: result.total,
          totalPages: result.totalPages,
          hasNext: result.hasNext,
          hasPrev: result.hasPrev,
        },
      },
    });
  }
);

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

export const updateOnlineStatus = catchAsync(
  async (req: AuthRequest, res: Response) => {
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
  }
);
