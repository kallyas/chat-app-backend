import mongoose from 'mongoose';
import { ChatRoom, IChatRoom, ChatRoomType, Message, IMessage, MessageType, User, IUser } from '@/models';
import { AppError } from '@/middleware';
import { toObjectId, getPaginationInfo } from '@/utils';
import { logger } from '@/config/logger';
import { CreateChatRoomData, SendMessageData, GetMessagesQuery } from '@/types';

export class ChatService {
  static async createChatRoom(roomData: CreateChatRoomData): Promise<IChatRoom> {
    try {
      const { name, type, participants, description, createdBy } = roomData;

      // Validate participants exist
      const validParticipants = await User.find({
        _id: { $in: participants }
      }).select('_id');

      if (validParticipants.length !== participants.length) {
        throw new AppError('Some participants do not exist', 400);
      }

      // Ensure creator is in participants
      if (!participants.includes(createdBy)) {
        participants.push(createdBy);
      }

      // For private chats, check if room already exists
      if (type === ChatRoomType.PRIVATE) {
        if (participants.length !== 2) {
          throw new AppError('Private chat must have exactly 2 participants', 400);
        }

        const existingRoom = await ChatRoom.findOne({
          type: ChatRoomType.PRIVATE,
          participants: { $all: participants, $size: 2 }
        });

        if (existingRoom) {
          return existingRoom;
        }
      }

      const chatRoom = new ChatRoom({
        name: name || (type === ChatRoomType.PRIVATE ? undefined : name),
        type,
        participants: participants.map(p => toObjectId(p)),
        createdBy: toObjectId(createdBy),
        description,
      });

      await chatRoom.save();
      await chatRoom.populate('participants', 'username email profilePic isOnline');
      await chatRoom.populate('createdBy', 'username email profilePic');

      logger.info(`Chat room created: ${chatRoom._id} by ${createdBy}`);

      return chatRoom;
    } catch (error) {
      logger.error('Error in createChatRoom:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to create chat room', 500);
    }
  }

  static async getUserChatRooms(
    userId: string,
    page: number = 1,
    limit: number = 20
  ): Promise<{ chatRooms: IChatRoom[], total: number, totalPages: number, hasNext: boolean, hasPrev: boolean }> {
    try {
      const skip = (page - 1) * limit;
      
      const query = {
        participants: toObjectId(userId),
        isActive: true,
      };

      const [chatRooms, total] = await Promise.all([
        ChatRoom.find(query)
          .populate('participants', 'username email profilePic isOnline lastSeen')
          .populate('createdBy', 'username email profilePic')
          .populate('lastMessage.sender', 'username profilePic')
          .sort({ 'lastMessage.timestamp': -1, updatedAt: -1 })
          .skip(skip)
          .limit(limit),
        ChatRoom.countDocuments(query)
      ]);

      const totalPages = Math.ceil(total / limit);
      const hasNext = page < totalPages;
      const hasPrev = page > 1;

      return {
        chatRooms,
        total,
        totalPages,
        hasNext,
        hasPrev
      };
    } catch (error) {
      logger.error('Error in getUserChatRooms:', error);
      throw new AppError('Failed to get user chat rooms', 500);
    }
  }

  static async getChatRoomById(roomId: string, userId: string): Promise<IChatRoom> {
    try {
      const chatRoom = await ChatRoom.findOne({
        _id: toObjectId(roomId),
        participants: toObjectId(userId),
        isActive: true,
      })
        .populate('participants', 'username email profilePic isOnline lastSeen')
        .populate('createdBy', 'username email profilePic');

      if (!chatRoom) {
        throw new AppError('Chat room not found or access denied', 404);
      }

      return chatRoom;
    } catch (error) {
      logger.error('Error in getChatRoomById:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to get chat room', 500);
    }
  }

  static async sendMessage(messageData: SendMessageData): Promise<IMessage> {
    try {
      const { chatRoomId, senderId, content, type = MessageType.TEXT, replyTo, metadata } = messageData;

      // Verify user is participant in the chat room
      const chatRoom = await ChatRoom.findOne({
        _id: toObjectId(chatRoomId),
        participants: toObjectId(senderId),
        isActive: true,
      });

      if (!chatRoom) {
        throw new AppError('Chat room not found or access denied', 404);
      }

      // Verify reply message exists if replyTo is provided
      if (replyTo) {
        const replyMessage = await Message.findOne({
          _id: toObjectId(replyTo),
          chatRoomId: toObjectId(chatRoomId),
        });

        if (!replyMessage) {
          throw new AppError('Reply message not found', 404);
        }
      }

      const message = new Message({
        chatRoomId: toObjectId(chatRoomId),
        senderId: toObjectId(senderId),
        content,
        type,
        replyTo: replyTo ? toObjectId(replyTo) : undefined,
        metadata,
      });

      await message.save();

      // Update chat room's last message
      await chatRoom.updateLastMessage(content, toObjectId(senderId), type);

      // Populate message data
      await message.populate([
        { path: 'senderId', select: 'username profilePic' },
        { path: 'replyTo', select: 'content senderId type createdAt', populate: { path: 'senderId', select: 'username' } }
      ]);

      logger.info(`Message sent: ${message._id} in room ${chatRoomId}`);

      return message;
    } catch (error) {
      logger.error('Error in sendMessage:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to send message', 500);
    }
  }

  static async getMessages(chatRoomId: string, userId: string, query: GetMessagesQuery = {}): Promise<{
    messages: IMessage[];
    pagination: Record<string, any>;
  }> {
    try {
      const { page = 1, limit = 20, before } = query;

      // Verify user has access to chat room
      const chatRoom = await ChatRoom.findOne({
        _id: toObjectId(chatRoomId),
        participants: toObjectId(userId),
        isActive: true,
      });

      if (!chatRoom) {
        throw new AppError('Chat room not found or access denied', 404);
      }

      const filter: Record<string, any> = { chatRoomId: toObjectId(chatRoomId) };

      if (before) {
        const beforeMessage = await Message.findById(before);
        if (beforeMessage) {
          filter.createdAt = { $lt: beforeMessage.createdAt };
        }
      }

      const totalMessages = await Message.countDocuments(filter);

      const messages = await Message.find(filter)
        .populate('senderId', 'username profilePic')
        .populate({
          path: 'replyTo',
          select: 'content senderId type createdAt',
          populate: { path: 'senderId', select: 'username' }
        })
        .sort({ createdAt: -1 })
        .limit(limit)
        .skip((page - 1) * limit);

      const pagination = getPaginationInfo(page, limit, totalMessages);

      return { messages: messages.reverse(), pagination };
    } catch (error) {
      logger.error('Error in getMessages:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to get messages', 500);
    }
  }

  static async markMessagesAsRead(chatRoomId: string, userId: string): Promise<void> {
    try {
      await Message.markRoomMessagesAsRead(toObjectId(chatRoomId), toObjectId(userId));

      logger.info(`Messages marked as read in room ${chatRoomId} by user ${userId}`);
    } catch (error) {
      logger.error('Error in markMessagesAsRead:', error);
      throw new AppError('Failed to mark messages as read', 500);
    }
  }

  static async getUnreadMessageCount(chatRoomId: string, userId: string): Promise<number> {
    try {
      return await Message.getUnreadCount(toObjectId(chatRoomId), toObjectId(userId));
    } catch (error) {
      logger.error('Error in getUnreadMessageCount:', error);
      throw new AppError('Failed to get unread message count', 500);
    }
  }

  static async joinChatRoom(roomId: string, userId: string): Promise<IChatRoom> {
    try {
      const chatRoom = await ChatRoom.findById(roomId);

      if (!chatRoom) {
        throw new AppError('Chat room not found', 404);
      }

      if (chatRoom.type === ChatRoomType.PRIVATE) {
        throw new AppError('Cannot join private chat room', 400);
      }

      if (!chatRoom.isActive) {
        throw new AppError('Chat room is not active', 400);
      }

      if (chatRoom.participants.includes(toObjectId(userId))) {
        return chatRoom;
      }

      await chatRoom.addParticipant(toObjectId(userId));
      await chatRoom.populate('participants', 'username email profilePic isOnline');

      logger.info(`User ${userId} joined chat room ${roomId}`);

      return chatRoom;
    } catch (error) {
      logger.error('Error in joinChatRoom:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to join chat room', 500);
    }
  }

  static async leaveChatRoom(roomId: string, userId: string): Promise<void> {
    try {
      const chatRoom = await ChatRoom.findById(roomId);

      if (!chatRoom) {
        throw new AppError('Chat room not found', 404);
      }

      if (chatRoom.type === ChatRoomType.PRIVATE) {
        throw new AppError('Cannot leave private chat room', 400);
      }

      await chatRoom.removeParticipant(toObjectId(userId));

      logger.info(`User ${userId} left chat room ${roomId}`);
    } catch (error) {
      logger.error('Error in leaveChatRoom:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to leave chat room', 500);
    }
  }

  static async updateChatRoom(roomId: string, userId: string, updateData: Partial<IChatRoom>): Promise<IChatRoom> {
    try {
      const chatRoom = await ChatRoom.findOne({
        _id: toObjectId(roomId),
        participants: toObjectId(userId),
      });

      if (!chatRoom) {
        throw new AppError('Chat room not found or access denied', 404);
      }

      // Only allow certain updates and check permissions
      const allowedUpdates = ['name', 'description', 'avatar'];
      const updates: Record<string, any> = {};

      Object.keys(updateData).forEach(key => {
        if (allowedUpdates.includes(key)) {
          updates[key] = (updateData as Record<string, any>)[key];
        }
      });

      // For group chats, only creator can update certain fields
      if (chatRoom.type === ChatRoomType.GROUP) {
        if (!chatRoom.createdBy.equals(toObjectId(userId))) {
          throw new AppError('Only the room creator can update this room', 403);
        }
      }

      const updatedRoom = await ChatRoom.findByIdAndUpdate(
        roomId,
        updates,
        { new: true, runValidators: true }
      ).populate('participants', 'username email profilePic isOnline');

      logger.info(`Chat room updated: ${roomId} by ${userId}`);

      return updatedRoom!;
    } catch (error) {
      logger.error('Error in updateChatRoom:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to update chat room', 500);
    }
  }

  static async deleteChatRoom(roomId: string, userId: string): Promise<void> {
    try {
      const chatRoom = await ChatRoom.findById(roomId);

      if (!chatRoom) {
        throw new AppError('Chat room not found', 404);
      }

      if (!chatRoom.createdBy.equals(toObjectId(userId))) {
        throw new AppError('Only the room creator can delete this room', 403);
      }

      chatRoom.isActive = false;
      await chatRoom.save();

      logger.info(`Chat room deleted: ${roomId} by ${userId}`);
    } catch (error) {
      logger.error('Error in deleteChatRoom:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to delete chat room', 500);
    }
  }

  static async editMessage(messageId: string, userId: string, newContent: string): Promise<IMessage> {
    try {
      const message = await Message.findOne({
        _id: toObjectId(messageId),
        senderId: toObjectId(userId),
      });

      if (!message) {
        throw new AppError('Message not found or access denied', 404);
      }

      // Check if message is older than 24 hours (optional business rule)
      const messageAge = Date.now() - message.createdAt.getTime();
      const maxEditTime = 24 * 60 * 60 * 1000; // 24 hours

      if (messageAge > maxEditTime) {
        throw new AppError('Message is too old to edit', 400);
      }

      await message.editContent(newContent);
      await message.populate('senderId', 'username profilePic');

      logger.info(`Message edited: ${messageId} by ${userId}`);

      return message;
    } catch (error) {
      logger.error('Error in editMessage:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to edit message', 500);
    }
  }

  static async deleteMessage(messageId: string, userId: string): Promise<void> {
    try {
      const message = await Message.findOne({
        _id: toObjectId(messageId),
        senderId: toObjectId(userId),
      });

      if (!message) {
        throw new AppError('Message not found or access denied', 404);
      }

      await Message.findByIdAndDelete(messageId);

      logger.info(`Message deleted: ${messageId} by ${userId}`);
    } catch (error) {
      logger.error('Error in deleteMessage:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to delete message', 500);
    }
  }
}