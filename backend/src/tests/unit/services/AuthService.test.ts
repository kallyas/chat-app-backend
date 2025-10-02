import { AuthService } from '@/services/authService';
import { AppError } from '@/middleware';

describe('AuthService', () => {
  const validUserData = {
    email: 'test@example.com',
    username: 'testuser',
    password: 'password123',
  };

  describe('registerUser', () => {
    it('should register a new user successfully', async () => {
      const user = await AuthService.registerUser(validUserData);

      expect(user.email).toBe(validUserData.email);
      expect(user.username).toBe(validUserData.username);
      expect(user.password).not.toBe(validUserData.password);
      expect(user.isOnline).toBe(false);
    });

    it('should throw error if email already exists', async () => {
      await AuthService.registerUser(validUserData);

      await expect(
        AuthService.registerUser({
          ...validUserData,
          username: 'differentuser',
        })
      ).rejects.toThrow(AppError);
    });

    it('should throw error if username already exists', async () => {
      await AuthService.registerUser(validUserData);

      await expect(
        AuthService.registerUser({
          ...validUserData,
          email: 'different@example.com',
        })
      ).rejects.toThrow(AppError);
    });
  });

  describe('loginUser', () => {
    beforeEach(async () => {
      await AuthService.registerUser(validUserData);
    });

    it('should login user with correct credentials', async () => {
      const user = await AuthService.loginUser({
        email: validUserData.email,
        password: validUserData.password,
      });

      expect(user.email).toBe(validUserData.email);
      expect(user.isOnline).toBe(true);
    });

    it('should throw error with incorrect email', async () => {
      await expect(
        AuthService.loginUser({
          email: 'wrong@example.com',
          password: validUserData.password,
        })
      ).rejects.toThrow(AppError);
    });

    it('should throw error with incorrect password', async () => {
      await expect(
        AuthService.loginUser({
          email: validUserData.email,
          password: 'wrongpassword',
        })
      ).rejects.toThrow(AppError);
    });
  });

  describe('getUserById', () => {
    let userId: string;

    beforeEach(async () => {
      const user = await AuthService.registerUser(validUserData);
      userId = user._id.toString();
    });

    it('should return user by valid ID', async () => {
      const user = await AuthService.getUserById(userId);

      expect(user).toBeTruthy();
      expect(user!.email).toBe(validUserData.email);
    });

    it('should return null for invalid ID', async () => {
      const user = await AuthService.getUserById('507f1f77bcf86cd799439011');

      expect(user).toBeNull();
    });
  });

  describe('updateUserProfile', () => {
    let userId: string;

    beforeEach(async () => {
      const user = await AuthService.registerUser(validUserData);
      userId = user._id.toString();
    });

    it('should update user profile successfully', async () => {
      const updateData = {
        username: 'newusername',
        profilePic: 'http://example.com/pic.jpg',
      };

      const updatedUser = await AuthService.updateUserProfile(
        userId,
        updateData
      );

      expect(updatedUser.username).toBe(updateData.username);
      expect(updatedUser.profilePic).toBe(updateData.profilePic);
    });

    it('should not allow duplicate username', async () => {
      // Create another user
      await AuthService.registerUser({
        email: 'another@example.com',
        username: 'anotheruser',
        password: 'password123',
      });

      await expect(
        AuthService.updateUserProfile(userId, {
          username: 'anotheruser',
        })
      ).rejects.toThrow(AppError);
    });

    it('should throw error for non-existent user', async () => {
      await expect(
        AuthService.updateUserProfile('507f1f77bcf86cd799439011', {
          username: 'newusername',
        })
      ).rejects.toThrow(AppError);
    });
  });

  describe('searchUsers', () => {
    let currentUserId: string;

    beforeEach(async () => {
      const currentUser = await AuthService.registerUser(validUserData);
      currentUserId = currentUser._id.toString();

      // Create additional test users
      await AuthService.registerUser({
        email: 'john@example.com',
        username: 'johndoe',
        password: 'password123',
      });

      await AuthService.registerUser({
        email: 'jane@example.com',
        username: 'janedoe',
        password: 'password123',
      });
    });

    it('should search users by username', async () => {
      const result = await AuthService.searchUsers(
        'john',
        currentUserId,
        'username'
      );

      expect(result.users).toHaveLength(1);
      expect(result.users[0].username).toBe('johndoe');
    });

    it('should search users by email', async () => {
      const result = await AuthService.searchUsers(
        'jane@example.com',
        currentUserId,
        'email'
      );

      expect(result.users).toHaveLength(1);
      expect(result.users[0].email).toBe('jane@example.com');
    });

    it('should search users by both username and email', async () => {
      const result = await AuthService.searchUsers(
        'doe',
        currentUserId,
        'both'
      );

      expect(result.users).toHaveLength(2);
    });

    it('should exclude current user from results', async () => {
      const result = await AuthService.searchUsers(
        'test',
        currentUserId,
        'both'
      );

      expect(result.users).toHaveLength(0);
    });
  });
});
