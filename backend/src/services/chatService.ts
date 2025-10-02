import mongoose from 'mongoose';
import {
  ChatRoom,
  IChatRoom,
  ChatRoomType,
  Message,
  IMessage,
  MessageType,
  User,
  IUser,
} from '@/models';
import { AppError } from '@/middleware';
import {
  toObjectId,
  getPaginationInfo,
  validatePagination,
  calculateSkip,
} from '@/utils';
import { logger } from '@/config/logger';
import { config } from '@/config/environment';
import { CreateChatRoomData, SendMessageData, GetMessagesQuery } from '@/types';

export class ChatService {
  static async createChatRoom(
    roomData: CreateChatRoomData
  ): Promise<IChatRoom> {
    try {
      const { name, type, participants, description, createdBy } = roomData;

      // Validate participants exist
      const validParticipants = await User.find({
        _id: { $in: participants },
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
          throw new AppError(
            'Private chat must have exactly 2 participants',
            400
          );
        }

        // Sort participants to ensure consistent ordering for index optimization
        const sortedParticipants = participants
          .map(p => toObjectId(p))
          .sort((a, b) => a.toString().localeCompare(b.toString()));

        const existingRoom = await ChatRoom.findOne({
          type: ChatRoomType.PRIVATE,
          participants: sortedParticipants,
        });

        if (existingRoom) {
          return existingRoom;
        }

        // Use sorted participants for consistent index matching
        const chatRoom = new ChatRoom({
          name: name || (type === ChatRoomType.PRIVATE ? undefined : name),
          type,
          participants: sortedParticipants,
          createdBy: toObjectId(createdBy),
          description,
        });

        await chatRoom.save();
        await chatRoom.populate(
          'participants',
          'username email profilePic isOnline'
        );
        await chatRoom.populate('createdBy', 'username email profilePic');

        logger.info(`New private chat room created: ${chatRoom._id}`);
        return chatRoom;
      }

      // For group chats, no need to sort participants
      const chatRoom = new ChatRoom({
        name,
        type,
        participants: participants.map(p => toObjectId(p)),
        createdBy: toObjectId(createdBy),
        description,
      });

      await chatRoom.save();
      await chatRoom.populate(
        'participants',
        'username email profilePic isOnline'
      );
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
    page: any = 1,
    limit: any = 20
  ): Promise<{
    chatRooms: any[];
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  }> {
    try {
      // Validate pagination parameters
      const { page: validPage, limit: validLimit } = validatePagination(
        page,
        limit
      );
      const skip = calculateSkip(validPage, validLimit);
      const userObjectId = toObjectId(userId);

      // Use aggregation pipeline to avoid N+1 queries
      const [chatRoomsResult] = await ChatRoom.aggregate([
        // Match chat rooms for this user
        {
          $match: {
            participants: userObjectId,
            isActive: true,
          },
        },
        // Get total count
        {
          $facet: {
            metadata: [{ $count: 'total' }],
            chatRooms: [
              // Sort by last message timestamp
              { $sort: { 'lastMessage.timestamp': -1, updatedAt: -1 } },
              { $skip: skip },
              { $limit: validLimit },
              // Lookup participants
              {
                $lookup: {
                  from: 'users',
                  localField: 'participants',
                  foreignField: '_id',
                  as: 'participantDetails',
                },
              },
              // Lookup createdBy
              {
                $lookup: {
                  from: 'users',
                  localField: 'createdBy',
                  foreignField: '_id',
                  as: 'createdByDetails',
                },
              },
              // Lookup lastMessage sender
              {
                $lookup: {
                  from: 'users',
                  localField: 'lastMessage.sender',
                  foreignField: '_id',
                  as: 'lastMessageSenderDetails',
                },
              },
              // Project only needed fields
              {
                $project: {
                  name: 1,
                  type: 1,
                  isActive: 1,
                  createdAt: 1,
                  updatedAt: 1,
                  participants: {
                    $map: {
                      input: '$participantDetails',
                      as: 'p',
                      in: {
                        _id: '$$p._id',
                        username: '$$p.username',
                        email: '$$p.email',
                        profilePic: '$$p.profilePic',
                        isOnline: '$$p.isOnline',
                        lastSeen: '$$p.lastSeen',
                      },
                    },
                  },
                  createdBy: {
                    $let: {
                      vars: {
                        creator: { $arrayElemAt: ['$createdByDetails', 0] },
                      },
                      in: {
                        _id: '$$creator._id',
                        username: '$$creator.username',
                        email: '$$creator.email',
                        profilePic: '$$creator.profilePic',
                      },
                    },
                  },
                  lastMessage: {
                    $cond: {
                      if: { $gt: ['$lastMessage', null] },
                      then: {
                        content: '$lastMessage.content',
                        timestamp: '$lastMessage.timestamp',
                        sender: {
                          $let: {
                            vars: {
                              senderData: {
                                $arrayElemAt: ['$lastMessageSenderDetails', 0],
                              },
                            },
                            in: {
                              _id: '$$senderData._id',
                              username: '$$senderData.username',
                              profilePic: '$$senderData.profilePic',
                            },
                          },
                        },
                      },
                      else: null,
                    },
                  },
                },
              },
            ],
          },
        },
      ]);

      const total = chatRoomsResult.metadata[0]?.total || 0;
      const chatRooms = chatRoomsResult.chatRooms || [];
      const totalPages = Math.ceil(total / validLimit);
      const hasNext = validPage < totalPages;
      const hasPrev = validPage > 1;

      return {
        chatRooms,
        total,
        totalPages,
        hasNext,
        hasPrev,
      };
    } catch (error) {
      logger.error('Error in getUserChatRooms:', error);
      throw new AppError('Failed to get user chat rooms', 500);
    }
  }

  static async getChatRoomById(
    roomId: string,
    userId: string
  ): Promise<IChatRoom> {
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
      const {
        chatRoomId,
        senderId,
        content,
        type = MessageType.TEXT,
        replyTo,
        metadata,
      } = messageData;

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
        {
          path: 'replyTo',
          select: 'content senderId type createdAt',
          populate: { path: 'senderId', select: 'username' },
        },
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

  static async getMessages(
    chatRoomId: string,
    userId: string,
    query: GetMessagesQuery = {}
  ): Promise<{
    messages: IMessage[];
    pagination: Record<string, any>;
  }> {
    try {
      const { before } = query;

      // Validate pagination parameters
      const { page: validPage, limit: validLimit } = validatePagination(
        query.page,
        query.limit
      );

      // Verify user has access to chat room
      const chatRoom = await ChatRoom.findOne({
        _id: toObjectId(chatRoomId),
        participants: toObjectId(userId),
        isActive: true,
      });

      if (!chatRoom) {
        throw new AppError('Chat room not found or access denied', 404);
      }

      const filter: Record<string, any> = {
        chatRoomId: toObjectId(chatRoomId),
      };

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
          populate: { path: 'senderId', select: 'username' },
        })
        .sort({ createdAt: -1 })
        .limit(validLimit)
        .skip(calculateSkip(validPage, validLimit));

      const pagination = getPaginationInfo(
        validPage,
        validLimit,
        totalMessages
      );

      return { messages: messages.reverse(), pagination };
    } catch (error) {
      logger.error('Error in getMessages:', error);
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Failed to get messages', 500);
    }
  }

  static async markMessagesAsRead(
    chatRoomId: string,
    userId: string
  ): Promise<void> {
    try {
      await Message.markRoomMessagesAsRead(
        toObjectId(chatRoomId),
        toObjectId(userId)
      );

      logger.info(
        `Messages marked as read in room ${chatRoomId} by user ${userId}`
      );
    } catch (error) {
      logger.error('Error in markMessagesAsRead:', error);
      throw new AppError('Failed to mark messages as read', 500);
    }
  }

  static async getUnreadMessageCount(
    chatRoomId: string,
    userId: string
  ): Promise<number> {
    try {
      return await Message.getUnreadCount(
        toObjectId(chatRoomId),
        toObjectId(userId)
      );
    } catch (error) {
      logger.error('Error in getUnreadMessageCount:', error);
      throw new AppError('Failed to get unread message count', 500);
    }
  }

  static async joinChatRoom(
    roomId: string,
    userId: string
  ): Promise<IChatRoom> {
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
      await chatRoom.populate(
        'participants',
        'username email profilePic isOnline'
      );

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

  static async updateChatRoom(
    roomId: string,
    userId: string,
    updateData: Partial<IChatRoom>
  ): Promise<IChatRoom> {
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

      const updatedRoom = await ChatRoom.findByIdAndUpdate(roomId, updates, {
        new: true,
        runValidators: true,
      }).populate('participants', 'username email profilePic isOnline');

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

  static async editMessage(
    messageId: string,
    userId: string,
    newContent: string
  ): Promise<IMessage> {
    try {
      const message = await Message.findOne({
        _id: toObjectId(messageId),
        senderId: toObjectId(userId),
      });

      if (!message) {
        throw new AppError('Message not found or access denied', 404);
      }

      // Check if message is within edit time limit
      const messageAge = Date.now() - message.createdAt.getTime();

      if (messageAge > config.messages.editTimeLimitMs) {
        throw new AppError(
          `Messages can only be edited within ${config.messages.editTimeLimitHours} hours`,
          400
        );
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

      // Check if message is within delete time limit
      const messageAge = Date.now() - message.createdAt.getTime();

      if (messageAge > config.messages.deleteTimeLimitMs) {
        throw new AppError(
          `Messages can only be deleted within ${config.messages.deleteTimeLimitHours} hours`,
          400
        );
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
