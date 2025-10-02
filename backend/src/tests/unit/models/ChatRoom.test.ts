import mongoose from 'mongoose';
import { ChatRoom, ChatRoomType, IChatRoom } from '@/models/ChatRoom';
import { User } from '@/models/User';

describe('ChatRoom Model', () => {
  let user1Id: mongoose.Types.ObjectId;
  let user2Id: mongoose.Types.ObjectId;
  let user3Id: mongoose.Types.ObjectId;

  beforeEach(async () => {
    // Create test users
    const user1 = await User.create({
      email: 'user1@test.com',
      username: 'user1',
      password: 'password123',
    });
    const user2 = await User.create({
      email: 'user2@test.com',
      username: 'user2',
      password: 'password123',
    });
    const user3 = await User.create({
      email: 'user3@test.com',
      username: 'user3',
      password: 'password123',
    });

    user1Id = user1._id;
    user2Id = user2._id;
    user3Id = user3._id;
  });

  describe('Private Chat Room', () => {
    it('should create a private chat room with 2 participants', async () => {
      const chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1Id, user2Id],
        createdBy: user1Id,
      });

      expect(chatRoom.type).toBe(ChatRoomType.PRIVATE);
      expect(chatRoom.participants).toHaveLength(2);
      expect(chatRoom.isActive).toBe(true);
    });

    it('should fail to create private chat with more than 2 participants', async () => {
      await expect(
        ChatRoom.create({
          type: ChatRoomType.PRIVATE,
          participants: [user1Id, user2Id, user3Id],
          createdBy: user1Id,
        })
      ).rejects.toThrow('Private chat room must have exactly 2 participants');
    });

    it('should fail to create private chat with less than 2 participants', async () => {
      await expect(
        ChatRoom.create({
          type: ChatRoomType.PRIVATE,
          participants: [user1Id],
          createdBy: user1Id,
        })
      ).rejects.toThrow('Private chat room must have exactly 2 participants');
    });

    it('should not allow adding participants to private chat', async () => {
      const chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1Id, user2Id],
        createdBy: user1Id,
      });

      expect(() => chatRoom.addParticipant(user3Id)).toThrow(
        'Cannot add participants to private chat'
      );
    });
  });

  describe('Group Chat Room', () => {
    it('should create a group chat room with 3+ participants', async () => {
      const chatRoom = await ChatRoom.create({
        name: 'Test Group',
        type: ChatRoomType.GROUP,
        participants: [user1Id, user2Id, user3Id],
        createdBy: user1Id,
        description: 'A test group chat',
      });

      expect(chatRoom.type).toBe(ChatRoomType.GROUP);
      expect(chatRoom.name).toBe('Test Group');
      expect(chatRoom.participants).toHaveLength(3);
      expect(chatRoom.description).toBe('A test group chat');
    });

    it('should fail to create group chat with less than 3 participants', async () => {
      await expect(
        ChatRoom.create({
          name: 'Test Group',
          type: ChatRoomType.GROUP,
          participants: [user1Id, user2Id],
          createdBy: user1Id,
        })
      ).rejects.toThrow('Group chat room must have at least 3 participants');
    });

    it('should add participant to group chat', async () => {
      const chatRoom = await ChatRoom.create({
        name: 'Test Group',
        type: ChatRoomType.GROUP,
        participants: [user1Id, user2Id, user3Id],
        createdBy: user1Id,
      });

      const user4 = await User.create({
        email: 'user4@test.com',
        username: 'user4',
        password: 'password123',
      });

      await chatRoom.addParticipant(user4._id);

      expect(chatRoom.participants).toHaveLength(4);
      expect(chatRoom.participants).toContainEqual(user4._id);
    });

    it('should not add duplicate participant', async () => {
      const chatRoom = await ChatRoom.create({
        name: 'Test Group',
        type: ChatRoomType.GROUP,
        participants: [user1Id, user2Id, user3Id],
        createdBy: user1Id,
      });

      await chatRoom.addParticipant(user1Id);

      expect(chatRoom.participants).toHaveLength(3);
    });

    it('should remove participant from group chat', async () => {
      const user4 = await User.create({
        email: 'user4@test.com',
        username: 'user4',
        password: 'password123',
      });

      const chatRoom = await ChatRoom.create({
        name: 'Test Group',
        type: ChatRoomType.GROUP,
        participants: [user1Id, user2Id, user3Id, user4._id],
        createdBy: user1Id,
      });

      await chatRoom.removeParticipant(user4._id);

      expect(chatRoom.participants).toHaveLength(3);
      expect(chatRoom.participants).not.toContainEqual(user4._id);
    });
  });

  describe('updateLastMessage', () => {
    it('should update last message with text type', async () => {
      const chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1Id, user2Id],
        createdBy: user1Id,
      });

      await chatRoom.updateLastMessage('Hello World', user1Id);

      expect(chatRoom.lastMessage).toBeDefined();
      expect(chatRoom.lastMessage?.content).toBe('Hello World');
      expect(chatRoom.lastMessage?.sender.toString()).toBe(user1Id.toString());
      expect(chatRoom.lastMessage?.messageType).toBe('text');
      expect(chatRoom.lastMessage?.timestamp).toBeInstanceOf(Date);
    });

    it('should update last message with image type', async () => {
      const chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1Id, user2Id],
        createdBy: user1Id,
      });

      await chatRoom.updateLastMessage('image.jpg', user1Id, 'image');

      expect(chatRoom.lastMessage?.messageType).toBe('image');
    });

    it('should update last message with file type', async () => {
      const chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1Id, user2Id],
        createdBy: user1Id,
      });

      await chatRoom.updateLastMessage('document.pdf', user1Id, 'file');

      expect(chatRoom.lastMessage?.messageType).toBe('file');
    });
  });

  describe('Validations', () => {
    it('should enforce max length for room name', async () => {
      const longName = 'a'.repeat(51);

      await expect(
        ChatRoom.create({
          name: longName,
          type: ChatRoomType.GROUP,
          participants: [user1Id, user2Id, user3Id],
          createdBy: user1Id,
        })
      ).rejects.toThrow();
    });

    it('should enforce max length for description', async () => {
      const longDescription = 'a'.repeat(201);

      await expect(
        ChatRoom.create({
          name: 'Test Group',
          type: ChatRoomType.GROUP,
          participants: [user1Id, user2Id, user3Id],
          createdBy: user1Id,
          description: longDescription,
        })
      ).rejects.toThrow();
    });

    it('should trim name and description', async () => {
      const chatRoom = await ChatRoom.create({
        name: '  Test Group  ',
        type: ChatRoomType.GROUP,
        participants: [user1Id, user2Id, user3Id],
        createdBy: user1Id,
        description: '  Test Description  ',
      });

      expect(chatRoom.name).toBe('Test Group');
      expect(chatRoom.description).toBe('Test Description');
    });

    it('should set default avatar to empty string', async () => {
      const chatRoom = await ChatRoom.create({
        name: 'Test Group',
        type: ChatRoomType.GROUP,
        participants: [user1Id, user2Id, user3Id],
        createdBy: user1Id,
      });

      expect(chatRoom.avatar).toBe('');
    });
  });
});
