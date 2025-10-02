import request from 'supertest';
import { createApp } from '@/app';
import { User } from '@/models/User';

describe('Auth Integration Tests', () => {
  const app = createApp();

  // Generate unique test data for each test to avoid conflicts
  const generateUniqueUserData = (prefix = 'test') => ({
    email: `${prefix}-${Date.now()}-${Math.random().toString(36).substr(2, 5)}@example.com`,
    username: `${prefix}user-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
    password: 'password123',
    profilePic: 'http://example.com/pic.jpg',
  });

  const validUserData = generateUniqueUserData();

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send(validUserData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.email).toBe(validUserData.email);
      expect(response.body.data.user.username).toBe(validUserData.username);
      expect(response.body.data.user.password).toBeUndefined();
      expect(response.body.data.tokens.access).toBeDefined();
      expect(response.body.data.tokens.refresh).toBeDefined();
    });

    it('should return 400 for invalid email', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          ...validUserData,
          email: 'invalid-email',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('valid email');
    });

    it('should return 400 for short password', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          ...validUserData,
          password: '123',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('at least 6 characters');
    });

    it('should return 400 for duplicate email', async () => {
      // Register first user
      await request(app)
        .post('/api/auth/register')
        .send(validUserData);

      // Try to register with same email
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          ...validUserData,
          username: 'differentuser',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('already exists');
    });
  });

  describe('POST /api/auth/login', () => {
    let loginUserData: any;

    beforeEach(async () => {
      // Generate unique user data for each test
      loginUserData = generateUniqueUserData('login');
      
      // Register a user for login tests
      await request(app)
        .post('/api/auth/register')
        .send(loginUserData);
    });

    it('should login user with correct credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: loginUserData.email,
          password: loginUserData.password,
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.email).toBe(loginUserData.email);
      expect(response.body.data.user.isOnline).toBe(true);
      expect(response.body.data.tokens.access).toBeDefined();
      expect(response.body.data.tokens.refresh).toBeDefined();
    });

    it('should return 401 for incorrect email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'wrong@example.com',
          password: loginUserData.password,
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid credentials');
    });

    it('should return 401 for incorrect password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: loginUserData.email,
          password: 'wrongpassword',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid credentials');
    });

    it('should return 400 for missing email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          password: validUserData.password,
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Email is required');
    });
  });

  describe('GET /api/auth/me', () => {
    let accessToken: string;
    let uniqueUserData: any;

    beforeEach(async () => {
      uniqueUserData = generateUniqueUserData('me-get');
      
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(uniqueUserData);

      accessToken = registerResponse.body.data.tokens.access;
    });

    it('should return user profile with valid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.email).toBe(uniqueUserData.email);
      expect(response.body.data.user.password).toBeUndefined();
    });

    it('should return 401 without token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Access token required');
    });

    it('should return 401 with invalid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid token');
    });
  });

  describe('POST /api/auth/logout', () => {
    let accessToken: string;
    let logoutUserData: any;

    beforeEach(async () => {
      logoutUserData = generateUniqueUserData('logout');
      
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(logoutUserData);

      accessToken = registerResponse.body.data.tokens.access;
    });

    it('should logout user successfully', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('Logout successful');

      // Verify user is offline
      const user = await User.findOne({ email: logoutUserData.email });
      expect(user?.isOnline).toBe(false);
    });

    it('should return 401 without token', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/auth/me', () => {
    let accessToken: string;

    beforeEach(async () => {
      const uniqueUserData = generateUniqueUserData('me');
      
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(uniqueUserData);

      accessToken = registerResponse.body.data.tokens.access;
    });

    it('should update user profile successfully', async () => {
      const updateData = {
        username: 'newusername',
        profilePic: 'http://example.com/newpic.jpg',
      };

      const response = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.username).toBe(updateData.username);
      expect(response.body.data.user.profilePic).toBe(updateData.profilePic);
    });

    it('should return 400 for invalid username format', async () => {
      const response = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          username: 'invalid username with spaces',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should return 401 without token', async () => {
      const response = await request(app)
        .put('/api/auth/me')
        .send({ username: 'newusername' })
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });
});