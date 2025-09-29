import request from 'supertest';
import { createApp } from '@/app';
import { User } from '@/models/User';

describe('Auth Integration Tests', () => {
  const app = createApp();

  const validUserData = {
    email: 'test@example.com',
    username: 'testuser',
    password: 'password123',
    profilePic: 'http://example.com/pic.jpg',
  };

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
      expect(response.body.message).toContain('already registered');
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      // Register a user for login tests
      await request(app)
        .post('/api/auth/register')
        .send(validUserData);
    });

    it('should login user with correct credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: validUserData.email,
          password: validUserData.password,
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.email).toBe(validUserData.email);
      expect(response.body.data.user.isOnline).toBe(true);
      expect(response.body.data.tokens.access).toBeDefined();
      expect(response.body.data.tokens.refresh).toBeDefined();
    });

    it('should return 401 for incorrect email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'wrong@example.com',
          password: validUserData.password,
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid email or password');
    });

    it('should return 401 for incorrect password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: validUserData.email,
          password: 'wrongpassword',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid email or password');
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

    beforeEach(async () => {
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(validUserData);

      accessToken = registerResponse.body.data.tokens.access;
    });

    it('should return user profile with valid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.email).toBe(validUserData.email);
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

    beforeEach(async () => {
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(validUserData);

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
      const user = await User.findOne({ email: validUserData.email });
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
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(validUserData);

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