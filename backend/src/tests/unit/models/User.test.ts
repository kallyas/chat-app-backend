import { User, IUser } from '@/models/User';

describe('User Model', () => {
  const validUserData = {
    email: 'test@example.com',
    username: 'testuser',
    password: 'password123',
  };

  describe('User Creation', () => {
    it('should create a user with valid data', async () => {
      const user = new User(validUserData);
      const savedUser = await user.save();

      expect(savedUser.email).toBe(validUserData.email);
      expect(savedUser.username).toBe(validUserData.username);
      expect(savedUser.password).not.toBe(validUserData.password); // Password should be hashed
      expect(savedUser.isOnline).toBe(false);
      expect(savedUser.createdAt).toBeDefined();
    });

    it('should require email, username, and password', async () => {
      const user = new User({});

      await expect(user.save()).rejects.toThrow();
    });

    it('should not allow duplicate emails', async () => {
      const user1 = new User(validUserData);
      await user1.save();

      const user2 = new User({
        ...validUserData,
        username: 'differentuser',
      });

      await expect(user2.save()).rejects.toThrow();
    });

    it('should not allow duplicate usernames', async () => {
      const user1 = new User(validUserData);
      await user1.save();

      const user2 = new User({
        ...validUserData,
        email: 'different@example.com',
      });

      await expect(user2.save()).rejects.toThrow();
    });

    it('should validate email format', async () => {
      const user = new User({
        ...validUserData,
        email: 'invalid-email',
      });

      await expect(user.save()).rejects.toThrow();
    });

    it('should validate username format', async () => {
      const user = new User({
        ...validUserData,
        username: 'invalid user name',
      });

      await expect(user.save()).rejects.toThrow();
    });

    it('should require minimum password length', async () => {
      const user = new User({
        ...validUserData,
        password: '12345',
      });

      await expect(user.save()).rejects.toThrow();
    });
  });

  describe('Password Methods', () => {
    let user: IUser;

    beforeEach(async () => {
      user = new User(validUserData);
      await user.save();
    });

    it('should hash password before saving', () => {
      expect(user.password).not.toBe(validUserData.password);
      expect(user.password.length).toBeGreaterThan(
        validUserData.password.length
      );
    });

    it('should compare password correctly', async () => {
      const isMatch = await user.comparePassword(validUserData.password);
      expect(isMatch).toBe(true);
    });

    it('should reject incorrect password', async () => {
      const isMatch = await user.comparePassword('wrongpassword');
      expect(isMatch).toBe(false);
    });
  });

  describe('JSON Serialization', () => {
    it('should not include password in JSON output', async () => {
      const user = new User(validUserData);
      await user.save();

      const userJSON = user.toJSON();

      expect(userJSON.password).toBeUndefined();
      expect(userJSON.resetPasswordToken).toBeUndefined();
      expect(userJSON.resetPasswordExpire).toBeUndefined();
      expect(userJSON.email).toBeDefined();
      expect(userJSON.username).toBeDefined();
    });
  });
});
