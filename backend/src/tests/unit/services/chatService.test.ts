import mongoose from 'mongoose';
import { ChatService } from '@/services/chatService';
import { User } from '@/models/User';
import { ChatRoom, ChatRoomType } from '@/models/ChatRoom';
import { Message, MessageType } from '@/models/Message';

describe('ChatService', () => {
  let user1: any;
  let user2: any;
  let user3: any;

  beforeEach(async () => {
    user1 = await User.create({
      email: 'user1@test.com',
      username: 'user1',
      password: 'password123',
    });

    user2 = await User.create({
      email: 'user2@test.com',
      username: 'user2',
      password: 'password123',
    });

    user3 = await User.create({
      email: 'user3@test.com',
      username: 'user3',
      password: 'password123',
    });
  });

  describe('createChatRoom', () => {
    it('should create a private chat room', async () => {
      const roomData = {
        type: ChatRoomType.PRIVATE,
        participants: [user1._id.toString(), user2._id.toString()],
        createdBy: user1._id.toString(),
      };

      const chatRoom = await ChatService.createChatRoom(roomData);

      expect(chatRoom.type).toBe(ChatRoomType.PRIVATE);
      expect(chatRoom.participants).toHaveLength(2);
    });

    it('should return existing private chat room if it exists', async () => {
      const roomData = {
        type: ChatRoomType.PRIVATE,
        participants: [user1._id.toString(), user2._id.toString()],
        createdBy: user1._id.toString(),
      };

      const chatRoom1 = await ChatService.createChatRoom(roomData);
      const chatRoom2 = await ChatService.createChatRoom(roomData);

      expect(chatRoom1._id.toString()).toBe(chatRoom2._id.toString());
    });

    it('should create a group chat room', async () => {
      const roomData = {
        name: 'Test Group',
        type: ChatRoomType.GROUP,
        participants: [
          user1._id.toString(),
          user2._id.toString(),
          user3._id.toString(),
        ],
        createdBy: user1._id.toString(),
        description: 'Test group description',
      };

      const chatRoom = await ChatService.createChatRoom(roomData);

      expect(chatRoom.type).toBe(ChatRoomType.GROUP);
      expect(chatRoom.name).toBe('Test Group');
      expect(chatRoom.participants).toHaveLength(3);
    });

    it('should throw error if participants do not exist', async () => {
      const roomData = {
        type: ChatRoomType.PRIVATE,
        participants: [
          user1._id.toString(),
          new mongoose.Types.ObjectId().toString(),
        ],
        createdBy: user1._id.toString(),
      };

      await expect(ChatService.createChatRoom(roomData)).rejects.toThrow(
        'Some participants do not exist'
      );
    });
  });

  describe('sendMessage', () => {
    let chatRoom: any;

    beforeEach(async () => {
      chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1._id, user2._id],
        createdBy: user1._id,
      });
    });

    it('should send a text message', async () => {
      const messageData = {
        chatRoomId: chatRoom._id.toString(),
        senderId: user1._id.toString(),
        content: 'Hello World',
        type: MessageType.TEXT,
      };

      const message = await ChatService.sendMessage(messageData);

      expect(message.content).toBe('Hello World');
      expect(message.type).toBe(MessageType.TEXT);
    });
  });

  describe('getMessages', () => {
    let chatRoom: any;

    beforeEach(async () => {
      chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1._id, user2._id],
        createdBy: user1._id,
      });

      // Create test messages
      for (let i = 0; i < 15; i++) {
        await Message.create({
          chatRoomId: chatRoom._id,
          senderId: i % 2 === 0 ? user1._id : user2._id,
          content: `Test message ${i + 1}`,
        });
      }
    });

    it('should get paginated messages', async () => {
      const result = await ChatService.getMessages(
        chatRoom._id.toString(),
        user1._id.toString(),
        { page: 1, limit: 10 }
      );

      expect(result.messages).toHaveLength(10);
      expect(result.pagination.totalItems).toBe(15);
      expect(result.pagination.totalPages).toBe(2);
    });
  });

  describe('getUserChatRooms', () => {
    beforeEach(async () => {
      // Create chat rooms for user1
      await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1._id, user2._id],
        createdBy: user1._id,
      });

      await ChatRoom.create({
        name: 'Group 1',
        type: ChatRoomType.GROUP,
        participants: [user1._id, user2._id, user3._id],
        createdBy: user1._id,
      });
    });

    it('should get all chat rooms for a user', async () => {
      const result = await ChatService.getUserChatRooms(
        user1._id.toString(),
        1,
        10
      );

      expect(result.chatRooms).toHaveLength(2);
    });
  });

  describe('markMessagesAsRead', () => {
    let chatRoom: any;

    beforeEach(async () => {
      chatRoom = await ChatRoom.create({
        type: ChatRoomType.PRIVATE,
        participants: [user1._id, user2._id],
        createdBy: user1._id,
      });

      // Create unread messages
      await Message.create({
        chatRoomId: chatRoom._id,
        senderId: user1._id,
        content: 'Message 1',
      });
      await Message.create({
        chatRoomId: chatRoom._id,
        senderId: user1._id,
        content: 'Message 2',
      });
    });

    it('should mark all messages as read for a user', async () => {
      await ChatService.markMessagesAsRead(
        chatRoom._id.toString(),
        user2._id.toString()
      );

      const unreadCount = await Message.getUnreadCount(chatRoom._id, user2._id);
      expect(unreadCount).toBe(0);
    });
  });
});
