import mongoose from 'mongoose';
import { Message, MessageType, MessageStatus, IMessage } from '@/models/Message';
import { ChatRoom, ChatRoomType } from '@/models/ChatRoom';
import { User } from '@/models/User';

describe('Message Model', () => {
  let user1Id: mongoose.Types.ObjectId;
  let user2Id: mongoose.Types.ObjectId;
  let chatRoomId: mongoose.Types.ObjectId;

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

    user1Id = user1._id;
    user2Id = user2._id;

    // Create a chat room
    const chatRoom = await ChatRoom.create({
      type: ChatRoomType.PRIVATE,
      participants: [user1Id, user2Id],
      createdBy: user1Id,
    });

    chatRoomId = chatRoom._id;
  });

  describe('Message Creation', () => {
    it('should create a text message', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'Hello World',
        type: MessageType.TEXT,
      });

      expect(message.content).toBe('Hello World');
      expect(message.type).toBe(MessageType.TEXT);
      expect(message.status).toBe(MessageStatus.SENT);
      expect(message.edited).toBe(false);
      expect(message.readBy).toHaveLength(0);
    });

    it('should create an image message', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'https://example.com/image.jpg',
        type: MessageType.IMAGE,
        metadata: {
          imageWidth: 1920,
          imageHeight: 1080,
        },
      });

      expect(message.type).toBe(MessageType.IMAGE);
      expect(message.metadata?.imageWidth).toBe(1920);
      expect(message.metadata?.imageHeight).toBe(1080);
    });

    it('should create a file message', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'https://example.com/document.pdf',
        type: MessageType.FILE,
        metadata: {
          fileName: 'document.pdf',
          fileSize: 1024000,
          mimeType: 'application/pdf',
        },
      });

      expect(message.type).toBe(MessageType.FILE);
      expect(message.metadata?.fileName).toBe('document.pdf');
      expect(message.metadata?.fileSize).toBe(1024000);
      expect(message.metadata?.mimeType).toBe('application/pdf');
    });

    it('should create a reply message', async () => {
      const originalMessage = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'Original message',
      });

      const replyMessage = await Message.create({
        chatRoomId,
        senderId: user2Id,
        content: 'Reply message',
        replyTo: originalMessage._id,
      });

      expect(replyMessage.replyTo?.toString()).toBe(originalMessage._id.toString());
    });
  });

  describe('markAsRead', () => {
    it('should mark message as read by a user', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'Test message',
      });

      await message.markAsRead(user2Id);

      expect(message.readBy).toHaveLength(1);
      expect(message.readBy[0].userId.toString()).toBe(user2Id.toString());
      expect(message.readBy[0].readAt).toBeInstanceOf(Date);
    });

    it('should not duplicate read status for same user', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'Test message',
      });

      await message.markAsRead(user2Id);
      await message.markAsRead(user2Id);

      expect(message.readBy).toHaveLength(1);
    });

    it('should allow multiple users to mark as read', async () => {
      const user3 = await User.create({
        email: 'user3@test.com',
        username: 'user3',
        password: 'password123',
      });

      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'Test message',
      });

      await message.markAsRead(user2Id);
      await message.markAsRead(user3._id);

      expect(message.readBy).toHaveLength(2);
    });
  });

  describe('markAsDelivered', () => {
    it('should mark message as delivered', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'Test message',
      });

      await message.markAsDelivered();

      expect(message.status).toBe(MessageStatus.DELIVERED);
    });
  });

  describe('editContent', () => {
    it('should edit message content', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: 'Original content',
      });

      await message.editContent('Edited content');

      expect(message.content).toBe('Edited content');
      expect(message.edited).toBe(true);
      expect(message.editedAt).toBeInstanceOf(Date);
    });
  });

  describe('Static Methods', () => {
    describe('getUnreadCount', () => {
      it('should count unread messages for a user', async () => {
        // Create messages from user1 to user2
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 1',
        });
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 2',
        });
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 3',
        });

        const unreadCount = await Message.getUnreadCount(chatRoomId, user2Id);

        expect(unreadCount).toBe(3);
      });

      it('should not count messages sent by the user', async () => {
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message from user1',
        });
        await Message.create({
          chatRoomId,
          senderId: user2Id,
          content: 'Message from user2',
        });

        const unreadCount = await Message.getUnreadCount(chatRoomId, user2Id);

        expect(unreadCount).toBe(1);
      });

      it('should not count messages already read by the user', async () => {
        const message1 = await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 1',
        });
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 2',
        });

        await message1.markAsRead(user2Id);

        const unreadCount = await Message.getUnreadCount(chatRoomId, user2Id);

        expect(unreadCount).toBe(1);
      });
    });

    describe('markRoomMessagesAsRead', () => {
      it('should mark all unread messages in a room as read', async () => {
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 1',
        });
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 2',
        });
        await Message.create({
          chatRoomId,
          senderId: user1Id,
          content: 'Message 3',
        });

        await Message.markRoomMessagesAsRead(chatRoomId, user2Id);

        const unreadCount = await Message.getUnreadCount(chatRoomId, user2Id);
        expect(unreadCount).toBe(0);
      });

      it('should not mark messages sent by the user', async () => {
        await Message.create({
          chatRoomId,
          senderId: user2Id,
          content: 'Message from user2',
        });

        await Message.markRoomMessagesAsRead(chatRoomId, user2Id);

        const messages = await Message.find({ chatRoomId, senderId: user2Id });
        expect(messages[0].readBy).toHaveLength(0);
      });
    });
  });

  describe('Validations', () => {
    it('should require chatRoomId', async () => {
      await expect(
        Message.create({
          senderId: user1Id,
          content: 'Test message',
        })
      ).rejects.toThrow();
    });

    it('should require senderId', async () => {
      await expect(
        Message.create({
          chatRoomId,
          content: 'Test message',
        })
      ).rejects.toThrow();
    });

    it('should require content', async () => {
      await expect(
        Message.create({
          chatRoomId,
          senderId: user1Id,
        })
      ).rejects.toThrow();
    });

    it('should enforce max length for content', async () => {
      const longContent = 'a'.repeat(2001);

      await expect(
        Message.create({
          chatRoomId,
          senderId: user1Id,
          content: longContent,
        })
      ).rejects.toThrow();
    });

    it('should trim content', async () => {
      const message = await Message.create({
        chatRoomId,
        senderId: user1Id,
        content: '  Test message  ',
      });

      expect(message.content).toBe('Test message');
    });
  });
});
