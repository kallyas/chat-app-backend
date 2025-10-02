import { User, IUser } from '@/models';
import { AppError } from '@/middleware';
import { generateResetToken, sanitizeUser, validatePagination, calculateSkip } from '@/utils';
import { logger } from '@/config/logger';
import { RegisterUserData, LoginUserData } from '@/types';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';

export class AuthService {
  static async registerUser(userData: RegisterUserData): Promise<IUser> {
    try {
      const { email, username, password, profilePic } = userData;

      // Check both email and username in parallel to prevent timing attacks
      const [existingUserByEmail, existingUserByUsername] = await Promise.all([
        User.findOne({ email }),
        User.findOne({ username })
      ]);

      // Use generic error message to prevent account enumeration
      if (existingUserByEmail || existingUserByUsername) {
        throw new AppError('Account already exists with provided credentials', 400);
      }

      const user = new User({
        email,
        username,
        password,
        profilePic: profilePic || '',
      });

      await user.save();

      logger.info(`New user registered: ${user.email}`);

      return user;
    } catch (error) {
      logger.error('Error in registerUser:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to register user', 500);
    }
  }

  static async loginUser(loginData: LoginUserData): Promise<IUser> {
    try {
      const { email, password } = loginData;

      const user = await User.findOne({ email }).select('+password');

      // Always perform password comparison to prevent timing attacks
      // If user doesn't exist, compare against a dummy hash
      const passwordHash = user?.password || await bcrypt.hash('dummy-password', 12);
      const isPasswordCorrect = await bcrypt.compare(password, passwordHash);

      // Check both user existence and password correctness together
      if (!user || !isPasswordCorrect) {
        throw new AppError('Invalid credentials', 401);
      }

      user.isOnline = true;
      user.lastSeen = new Date();
      await user.save();

      logger.info(`User logged in: ${user.email}`);

      return user;
    } catch (error) {
      logger.error('Error in loginUser:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to login user', 500);
    }
  }

  static async logoutUser(userId: string): Promise<void> {
    try {
      await User.findByIdAndUpdate(userId, {
        isOnline: false,
        lastSeen: new Date(),
      });

      logger.info(`User logged out: ${userId}`);
    } catch (error) {
      logger.error('Error in logoutUser:', error);
      throw new AppError('Failed to logout user', 500);
    }
  }

  static async getUserById(userId: string): Promise<IUser | null> {
    try {
      const user = await User.findById(userId);
      return user;
    } catch (error) {
      logger.error('Error in getUserById:', error);
      throw new AppError('Failed to get user', 500);
    }
  }

  static async updateUserProfile(userId: string, updateData: Partial<IUser>): Promise<IUser> {
    try {
      const allowedUpdates = ['username', 'profilePic', 'password'];
      const updates: Partial<IUser> = {};

      Object.keys(updateData).forEach(key => {
        if (allowedUpdates.includes(key)) {
          (updates as Record<string, any>)[key] = (updateData as Record<string, any>)[key];
        }
      });

      if (updates.username) {
        const existingUser = await User.findOne({
          username: updates.username,
          _id: { $ne: userId }
        });

        if (existingUser) {
          throw new AppError('Username already taken', 400);
        }
      }

      // Increment token version if password is being updated to invalidate existing tokens
      if (updates.password) {
        (updates as any).tokenVersion = { $inc: 1 };
      }

      const user = await User.findByIdAndUpdate(
        userId,
        updates.password ? { ...updates, $inc: { tokenVersion: 1 } } : updates,
        { new: true, runValidators: true }
      );

      if (!user) {
        throw new AppError('User not found', 404);
      }

      logger.info(`User profile updated: ${user.email}`);

      return user;
    } catch (error: any) {
      logger.error('Error in updateUserProfile:', error);
      if (error instanceof AppError) {
        throw error;
      }
      if (error.name === 'ValidationError') {
        const errors = Object.values(error.errors).map((el: any) => el.message);
        throw new AppError(`Invalid input data: ${errors.join('. ')}`, 400);
      }
      throw new AppError('Failed to update profile', 500);
    }
  }

  static async initiatePasswordReset(email: string): Promise<string> {
    try {
      const user = await User.findOne({ email });

      // Generate token regardless of user existence to prevent timing attacks
      const { token, hashedToken } = generateResetToken();

      if (user) {
        user.resetPasswordToken = hashedToken;
        user.resetPasswordExpire = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
        await user.save();
        logger.info(`Password reset initiated for: ${email}`);
      } else {
        // Log attempt but don't reveal user doesn't exist
        logger.warn(`Password reset attempted for non-existent email: ${email}`);
      }

      // Always return success to prevent enumeration
      // In production, you should send email only if user exists
      return token;
    } catch (error) {
      logger.error('Error in initiatePasswordReset:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to initiate password reset', 500);
    }
  }

  static async resetPassword(token: string, newPassword: string): Promise<void> {
    try {
      const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

      const user = await User.findOne({
        resetPasswordToken: hashedToken,
        resetPasswordExpire: { $gt: Date.now() },
      });

      if (!user) {
        throw new AppError('Token is invalid or has expired', 400);
      }

      user.password = newPassword;
      user.resetPasswordToken = undefined;
      user.resetPasswordExpire = undefined;
      user.tokenVersion += 1; // Invalidate all existing tokens
      await user.save();

      logger.info(`Password reset completed for: ${user.email}`);
    } catch (error) {
      logger.error('Error in resetPassword:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to reset password', 500);
    }
  }

  static async searchUsers(
    query: string,
    currentUserId: string,
    type: 'username' | 'email' | 'both' = 'both',
    page: any = 1,
    limit: any = 20
  ): Promise<{ users: IUser[], total: number, totalPages: number, hasNext: boolean, hasPrev: boolean }> {
    try {
      // Validate pagination parameters
      const { page: validPage, limit: validLimit } = validatePagination(page, limit);

      const searchConditions: Record<string, any> = {
        _id: { $ne: currentUserId },
      };

      if (type === 'username') {
        searchConditions.username = { $regex: query, $options: 'i' };
      } else if (type === 'email') {
        searchConditions.email = { $regex: query, $options: 'i' };
      } else {
        searchConditions.$or = [
          { username: { $regex: query, $options: 'i' } },
          { email: { $regex: query, $options: 'i' } },
        ];
      }

      // Calculate pagination
      const skip = calculateSkip(validPage, validLimit);
      
      // Get total count and users in parallel
      const [users, total] = await Promise.all([
        User.find(searchConditions)
          .select('username email profilePic isOnline lastSeen createdAt updatedAt')
          .skip(skip)
          .limit(validLimit)
          .sort({ username: 1 }),
        User.countDocuments(searchConditions)
      ]);

      const totalPages = Math.ceil(total / validLimit);
      const hasNext = validPage < totalPages;
      const hasPrev = validPage > 1;

      return {
        users,
        total,
        totalPages,
        hasNext,
        hasPrev
      };
    } catch (error) {
      logger.error('Error in searchUsers:', error);
      throw new AppError('Failed to search users', 500);
    }
  }

  static async updateUserOnlineStatus(userId: string, isOnline: boolean): Promise<void> {
    try {
      await User.findByIdAndUpdate(userId, {
        isOnline,
        lastSeen: new Date(),
      });
    } catch (error) {
      logger.error('Error in updateUserOnlineStatus:', error);
      throw new AppError('Failed to update online status', 500);
    }
  }

  static async getOnlineUsers(
    page: any = 1,
    limit: any = 20
  ): Promise<{ users: IUser[], total: number, totalPages: number, hasNext: boolean, hasPrev: boolean }> {
    try {
      // Validate pagination parameters
      const { page: validPage, limit: validLimit } = validatePagination(page, limit);
      const skip = calculateSkip(validPage, validLimit);

      const [users, total] = await Promise.all([
        User.find({ isOnline: true })
          .select('username email profilePic isOnline lastSeen createdAt updatedAt')
          .skip(skip)
          .limit(validLimit)
          .sort({ lastSeen: -1 }),
        User.countDocuments({ isOnline: true })
      ]);

      const totalPages = Math.ceil(total / validLimit);
      const hasNext = validPage < totalPages;
      const hasPrev = validPage > 1;

      return {
        users,
        total,
        totalPages,
        hasNext,
        hasPrev
      };
    } catch (error) {
      logger.error('Error in getOnlineUsers:', error);
      throw new AppError('Failed to get online users', 500);
    }
  }
}