import request from 'supertest';
import { createApp } from '@/app';
import { User } from '@/models/User';

describe('User Integration Tests', () => {
  const app = createApp();
  let accessToken: string;
  let userId: string;

  beforeEach(async () => {
    // Create a test user and get token
    const userData = {
      email: `test-${Date.now()}@example.com`,
      username: `testuser-${Date.now()}`,
      password: 'password123',
    };

    const response = await request(app)
      .post('/api/auth/register')
      .send(userData);

    accessToken = response.body.data.tokens.access;
    userId = response.body.data.user._id;
  });

  describe('GET /api/users/me', () => {
    it('should get current user profile', async () => {
      const response = await request(app)
        .get('/api/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.password).toBeUndefined();
    });

    it('should return 401 without token', async () => {
      await request(app).get('/api/users/me').expect(401);
    });
  });

  describe('PUT /api/users/me', () => {
    it('should update user profile', async () => {
      const updateData = {
        username: 'newusername',
        profilePic: 'http://example.com/newpic.jpg',
      };

      const response = await request(app)
        .put('/api/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.username).toBe(updateData.username);
      expect(response.body.data.user.profilePic).toBe(updateData.profilePic);
    });

    it('should return 400 for invalid username', async () => {
      const response = await request(app)
        .put('/api/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ username: 'invalid user' })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/users/search', () => {
    beforeEach(async () => {
      // Create additional users for search
      await User.create({
        email: 'john@example.com',
        username: 'johndoe',
        password: 'password123',
      });
      await User.create({
        email: 'jane@example.com',
        username: 'janedoe',
        password: 'password123',
      });
    });

    it('should search users by username', async () => {
      const response = await request(app)
        .get('/api/users/search')
        .query({ query: 'john' })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.users.length).toBeGreaterThan(0);
    });

    it('should search users by email', async () => {
      const response = await request(app)
        .get('/api/users/search')
        .query({ query: 'jane', type: 'email' })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should return 400 without search query', async () => {
      await request(app)
        .get('/api/users/search')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(400);
    });

    it('should paginate search results', async () => {
      const response = await request(app)
        .get('/api/users/search')
        .query({ query: 'doe', page: 1, limit: 1 })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.data.pagination).toBeDefined();
      expect(response.body.data.pagination.page).toBe(1);
      expect(response.body.data.pagination.limit).toBe(1);
    });
  });

  describe('GET /api/users/online', () => {
    beforeEach(async () => {
      // Create online users
      await User.create({
        email: 'online1@example.com',
        username: 'online1',
        password: 'password123',
        isOnline: true,
      });
      await User.create({
        email: 'online2@example.com',
        username: 'online2',
        password: 'password123',
        isOnline: true,
      });
    });

    it('should get list of online users', async () => {
      const response = await request(app)
        .get('/api/users/online')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.users).toBeDefined();
      expect(response.body.data.pagination).toBeDefined();
    });

    it('should not include current user in online list', async () => {
      const response = await request(app)
        .get('/api/users/online')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      const currentUserInList = response.body.data.users.find(
        (u: any) => u._id === userId
      );
      expect(currentUserInList).toBeUndefined();
    });
  });

  describe('GET /api/users/:userId', () => {
    let targetUser: any;

    beforeEach(async () => {
      targetUser = await User.create({
        email: 'target@example.com',
        username: 'targetuser',
        password: 'password123',
      });
    });

    it('should get user by ID', async () => {
      const response = await request(app)
        .get(`/api/users/${targetUser._id}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.username).toBe('targetuser');
      expect(response.body.data.user.password).toBeUndefined();
    });

    it('should return 404 for non-existent user', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      await request(app)
        .get(`/api/users/${fakeId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(404);
    });
  });

  describe('PUT /api/users/status', () => {
    it('should update online status', async () => {
      const response = await request(app)
        .put('/api/users/status')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ isOnline: false })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('Online status updated');
    });

    it('should return 400 for invalid isOnline value', async () => {
      await request(app)
        .put('/api/users/status')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ isOnline: 'invalid' })
        .expect(400);
    });
  });
});
