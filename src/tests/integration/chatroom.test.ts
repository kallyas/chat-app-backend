import request from 'supertest';
import { createApp } from '@/app';
import { User } from '@/models/User';
import { ChatRoom } from '@/models/ChatRoom';

describe('ChatRoom Integration Tests', () => {
  const app = createApp();

  let user1Token: string;
  let user2Token: string;
  let user1Id: string;
  let user2Id: string;

  beforeEach(async () => {
    // Register two users for testing
    const user1Data = {
      email: 'user1@example.com',
      username: 'user1',
      password: 'password123',
    };

    const user2Data = {
      email: 'user2@example.com',
      username: 'user2',
      password: 'password123',
    };

    const user1Response = await request(app)
      .post('/api/auth/register')
      .send(user1Data);

    const user2Response = await request(app)
      .post('/api/auth/register')
      .send(user2Data);

    user1Token = user1Response.body.data.tokens.access;
    user2Token = user2Response.body.data.tokens.access;
    user1Id = user1Response.body.data.user._id;
    user2Id = user2Response.body.data.user._id;
  });

  describe('POST /api/chatrooms', () => {
    it('should create a private chat room successfully', async () => {
      const chatRoomData = {
        type: 'private',
        participants: [user2Id],
      };

      const response = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.chatRoom.type).toBe('private');
      expect(response.body.data.chatRoom.participants).toHaveLength(2);
      expect(response.body.data.chatRoom.createdBy._id).toBe(user1Id);
    });

    it('should create a group chat room successfully', async () => {
      const user3Data = {
        email: 'user3@example.com',
        username: 'user3',
        password: 'password123',
      };

      const user3Response = await request(app)
        .post('/api/auth/register')
        .send(user3Data);

      const user3Id = user3Response.body.data.user._id;

      const chatRoomData = {
        name: 'Test Group',
        type: 'group',
        participants: [user2Id, user3Id],
        description: 'A test group chat',
      };

      const response = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.chatRoom.type).toBe('group');
      expect(response.body.data.chatRoom.name).toBe('Test Group');
      expect(response.body.data.chatRoom.description).toBe('A test group chat');
      expect(response.body.data.chatRoom.participants).toHaveLength(3);
    });

    it('should return existing private chat if already exists', async () => {
      const chatRoomData = {
        type: 'private',
        participants: [user2Id],
      };

      // Create first chat room
      const response1 = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData);

      // Try to create same chat room again
      const response2 = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData)
        .expect(201);

      expect(response1.body.data.chatRoom._id).toBe(response2.body.data.chatRoom._id);
    });

    it('should return 400 for invalid participants', async () => {
      const chatRoomData = {
        type: 'private',
        participants: ['invalid-id'],
      };

      const response = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should return 401 without authentication', async () => {
      const chatRoomData = {
        type: 'private',
        participants: [user2Id],
      };

      const response = await request(app)
        .post('/api/chatrooms')
        .send(chatRoomData)
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/chatrooms', () => {
    let chatRoomId: string;

    beforeEach(async () => {
      const chatRoomData = {
        type: 'private',
        participants: [user2Id],
      };

      const response = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData);

      chatRoomId = response.body.data.chatRoom._id;
    });

    it('should return user chat rooms', async () => {
      const response = await request(app)
        .get('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.chatRooms).toHaveLength(1);
      expect(response.body.data.chatRooms[0]._id).toBe(chatRoomId);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .get('/api/chatrooms')
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/chatrooms/:roomId', () => {
    let chatRoomId: string;

    beforeEach(async () => {
      const chatRoomData = {
        type: 'private',
        participants: [user2Id],
      };

      const response = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData);

      chatRoomId = response.body.data.chatRoom._id;
    });

    it('should return specific chat room', async () => {
      const response = await request(app)
        .get(`/api/chatrooms/${chatRoomId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.chatRoom._id).toBe(chatRoomId);
    });

    it('should return 404 for non-existent room', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .get(`/api/chatrooms/${fakeId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 for room user is not participant in', async () => {
      // Create another user
      const user3Data = {
        email: 'user3@example.com',
        username: 'user3',
        password: 'password123',
      };

      const user3Response = await request(app)
        .post('/api/auth/register')
        .send(user3Data);

      const user3Token = user3Response.body.data.tokens.access;

      const response = await request(app)
        .get(`/api/chatrooms/${chatRoomId}`)
        .set('Authorization', `Bearer ${user3Token}`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/chatrooms/:roomId/messages', () => {
    let chatRoomId: string;

    beforeEach(async () => {
      const chatRoomData = {
        type: 'private',
        participants: [user2Id],
      };

      const response = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData);

      chatRoomId = response.body.data.chatRoom._id;
    });

    it('should send message successfully', async () => {
      const messageData = {
        content: 'Hello, this is a test message!',
        type: 'text',
      };

      const response = await request(app)
        .post(`/api/chatrooms/${chatRoomId}/messages`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send(messageData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.message.content).toBe(messageData.content);
      expect(response.body.data.message.type).toBe(messageData.type);
      expect(response.body.data.message.senderId._id).toBe(user1Id);
    });

    it('should return 400 for empty message content', async () => {
      const messageData = {
        content: '',
      };

      const response = await request(app)
        .post(`/api/chatrooms/${chatRoomId}/messages`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send(messageData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should return 400 for message too long', async () => {
      const messageData = {
        content: 'a'.repeat(2001), // Exceeds 2000 character limit
      };

      const response = await request(app)
        .post(`/api/chatrooms/${chatRoomId}/messages`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send(messageData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent room', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const messageData = {
        content: 'Hello!',
      };

      const response = await request(app)
        .post(`/api/chatrooms/${fakeId}/messages`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send(messageData)
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/chatrooms/:roomId/messages', () => {
    let chatRoomId: string;

    beforeEach(async () => {
      const chatRoomData = {
        type: 'private',
        participants: [user2Id],
      };

      const chatRoomResponse = await request(app)
        .post('/api/chatrooms')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(chatRoomData);

      chatRoomId = chatRoomResponse.body.data.chatRoom._id;

      // Send a few test messages
      for (let i = 1; i <= 3; i++) {
        await request(app)
          .post(`/api/chatrooms/${chatRoomId}/messages`)
          .set('Authorization', `Bearer ${user1Token}`)
          .send({ content: `Test message ${i}` });
      }
    });

    it('should get messages from chat room', async () => {
      const response = await request(app)
        .get(`/api/chatrooms/${chatRoomId}/messages`)
        .set('Authorization', `Bearer ${user1Token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.messages).toHaveLength(3);
      expect(response.body.data.pagination).toBeDefined();
    });

    it('should support pagination', async () => {
      const response = await request(app)
        .get(`/api/chatrooms/${chatRoomId}/messages?page=1&limit=2`)
        .set('Authorization', `Bearer ${user1Token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.messages).toHaveLength(2);
      expect(response.body.data.pagination.totalItems).toBe(3);
      expect(response.body.data.pagination.currentPage).toBe(1);
    });
  });
});