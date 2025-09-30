import { User, IUser } from '@/models';
import { AppError } from '@/middleware';
import { generateResetToken, sanitizeUser } from '@/utils';
import { logger } from '@/config/logger';
import { RegisterUserData, LoginUserData } from '@/types';
import crypto from 'crypto';

export class AuthService {
  static async registerUser(userData: RegisterUserData): Promise<IUser> {
    try {
      const { email, username, password, profilePic } = userData;

      const existingUserByEmail = await User.findOne({ email });
      if (existingUserByEmail) {
        throw new AppError('Email already registered', 400);
      }

      const existingUserByUsername = await User.findOne({ username });
      if (existingUserByUsername) {
        throw new AppError('Username already taken', 400);
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
      if (!user) {
        throw new AppError('Invalid email or password', 401);
      }

      const isPasswordCorrect = await user.comparePassword(password);
      if (!isPasswordCorrect) {
        throw new AppError('Invalid email or password', 401);
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

      const user = await User.findByIdAndUpdate(
        userId,
        updates,
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
      if (!user) {
        throw new AppError('User not found with that email', 404);
      }

      const { token, hashedToken } = generateResetToken();

      user.resetPasswordToken = hashedToken;
      user.resetPasswordExpire = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
      await user.save();

      logger.info(`Password reset initiated for: ${email}`);

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

  static async searchUsers(query: string, currentUserId: string, type: 'username' | 'email' | 'both' = 'both'): Promise<IUser[]> {
    try {
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

      const users = await User.find(searchConditions)
        .select('username email profilePic isOnline lastSeen')
        .limit(10);

      return users;
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

  static async getOnlineUsers(): Promise<IUser[]> {
    try {
      const users = await User.find({ isOnline: true })
        .select('username email profilePic isOnline lastSeen');

      return users;
    } catch (error) {
      logger.error('Error in getOnlineUsers:', error);
      throw new AppError('Failed to get online users', 500);
    }
  }
}