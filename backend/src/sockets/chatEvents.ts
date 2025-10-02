import { Server, Socket } from 'socket.io';
import { ChatService } from '@/services';
import { AuthenticatedSocket } from './socketAuth';
import { logger } from '@/config/logger';
import { sendMessageSchema, objectIdSchema } from '@/utils';
import { User, ChatRoom } from '@/models';
import { socketRateLimiter, SOCKET_RATE_LIMITS } from '@/utils/socketRateLimit';

export interface TypingData {
  roomId: string;
  isTyping: boolean;
}

export interface JoinRoomData {
  roomId: string;
}

export interface SocketSendMessageData {
  roomId: string;
  content: string;
  type?: 'text' | 'image' | 'file';
  replyTo?: string;
  metadata?: any;
}

export interface MessageReadData {
  roomId: string;
  messageId: string;
}

export const setupChatEvents = (io: Server, socket: AuthenticatedSocket) => {
  // Join a chat room
  socket.on('joinRoom', async (data: JoinRoomData) => {
    try {
      // Rate limit check
      if (!socketRateLimiter.checkUser(socket.userId!, 'joinRoom', SOCKET_RATE_LIMITS.joinRoom)) {
        socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
        return;
      }

      const { roomId } = data;

      // Validate room ID format
      const { error } = objectIdSchema.validate(roomId);
      if (error) {
        socket.emit('error', { message: 'Invalid room ID format' });
        return;
      }

      // Check if user has access to this room
      const chatRoom = await ChatRoom.findOne({
        _id: roomId,
        participants: socket.userId,
        isActive: true,
      });

      if (!chatRoom) {
        socket.emit('error', { message: 'Room not found or access denied' });
        return;
      }

      // Join the socket room
      await socket.join(roomId);

      // Notify room members that user joined
      socket.to(roomId).emit('userJoined', {
        userId: socket.userId,
        username: socket.username,
        timestamp: new Date(),
      });

      // Send confirmation to the user
      socket.emit('roomJoined', {
        roomId,
        message: 'Successfully joined room',
      });

      logger.info(`User ${socket.username} joined room ${roomId}`);
    } catch (error) {
      logger.error('Error in joinRoom event:', error);
      socket.emit('error', { message: 'Failed to join room' });
    }
  });

  // Leave a chat room
  socket.on('leaveRoom', async (data: JoinRoomData) => {
    try {
      // Rate limit check
      if (!socketRateLimiter.checkUser(socket.userId!, 'leaveRoom', SOCKET_RATE_LIMITS.leaveRoom)) {
        socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
        return;
      }

      const { roomId } = data;

      // Validate room ID format
      const { error } = objectIdSchema.validate(roomId);
      if (error) {
        socket.emit('error', { message: 'Invalid room ID format' });
        return;
      }

      await socket.leave(roomId);

      // Notify room members that user left
      socket.to(roomId).emit('userLeft', {
        userId: socket.userId,
        username: socket.username,
        timestamp: new Date(),
      });

      // Send confirmation to the user
      socket.emit('roomLeft', {
        roomId,
        message: 'Successfully left room',
      });

      logger.info(`User ${socket.username} left room ${roomId}`);
    } catch (error) {
      logger.error('Error in leaveRoom event:', error);
      socket.emit('error', { message: 'Failed to leave room' });
    }
  });

  // Send a message
  socket.on('sendMessage', async (data: SocketSendMessageData) => {
    try {
      // Rate limit check
      if (!socketRateLimiter.checkUser(socket.userId!, 'sendMessage', SOCKET_RATE_LIMITS.sendMessage)) {
        socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
        return;
      }

      // Extract roomId separately for validation
      const { roomId, ...messageContent } = data;
      
      // Validate room ID format
      const roomValidation = objectIdSchema.validate(roomId);
      if (roomValidation.error) {
        socket.emit('error', { message: 'Invalid room ID format' });
        return;
      }

      // Validate message content
      const { error, value } = sendMessageSchema.validate(messageContent);
      if (error) {
        socket.emit('error', { message: error.details[0].message });
        return;
      }

      const messageData = {
        ...value,
        chatRoomId: roomId,
        senderId: socket.userId!,
      };

      const message = await ChatService.sendMessage(messageData);

      // Emit message to all users in the room
      io.to(roomId).emit('newMessage', {
        message,
        timestamp: new Date(),
      });

      logger.info(`Message sent by ${socket.username} in room ${roomId}`);
    } catch (error) {
      logger.error('Error in sendMessage event:', error);
      socket.emit('error', { message: 'Failed to send message' });
    }
  });

  // Handle typing indicators
  socket.on('typing', async (data: TypingData) => {
    try {
      // Rate limit check
      if (!socketRateLimiter.checkUser(socket.userId!, 'typing', SOCKET_RATE_LIMITS.typing)) {
        socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
        return;
      }

      const { roomId, isTyping } = data;

      // Validate roomId format
      const { error } = objectIdSchema.validate(roomId);
      if (error) {
        socket.emit('error', { message: 'Invalid room ID format' });
        return;
      }

      if (typeof isTyping !== 'boolean') {
        socket.emit('error', { message: 'isTyping must be a boolean' });
        return;
      }

      // Validate user is participant in the room
      const chatRoom = await ChatRoom.findOne({
        _id: roomId,
        participants: socket.userId,
        isActive: true,
      });

      if (!chatRoom) {
        socket.emit('error', { message: 'Room not found or access denied' });
        return;
      }

      // Emit typing status to all users in the room except sender
      socket.to(roomId).emit('userTyping', {
        userId: socket.userId,
        username: socket.username,
        isTyping,
        timestamp: new Date(),
      });

    } catch (error) {
      logger.error('Error in typing event:', error);
      socket.emit('error', { message: 'Failed to update typing status' });
    }
  });

  // Handle stop typing
  socket.on('stopTyping', (data: { roomId: string }) => {
    try {
      // Rate limit check
      if (!socketRateLimiter.checkUser(socket.userId!, 'stopTyping', SOCKET_RATE_LIMITS.stopTyping)) {
        socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
        return;
      }

      const { roomId } = data;

      socket.to(roomId).emit('userTyping', {
        userId: socket.userId,
        username: socket.username,
        isTyping: false,
        timestamp: new Date(),
      });

    } catch (error) {
      logger.error('Error in stopTyping event:', error);
    }
  });

  // Handle message read receipts
  socket.on('messageRead', async (data: MessageReadData) => {
    try {
      // Rate limit check
      if (!socketRateLimiter.checkUser(socket.userId!, 'messageRead', SOCKET_RATE_LIMITS.messageRead)) {
        socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
        return;
      }

      const { roomId, messageId } = data;

      // Validate IDs
      const roomValidation = objectIdSchema.validate(roomId);
      const messageValidation = objectIdSchema.validate(messageId);

      if (roomValidation.error || messageValidation.error) {
        socket.emit('error', { message: 'Invalid ID format' });
        return;
      }

      // Mark message as read (this would typically update the database)
      await ChatService.markMessagesAsRead(roomId, socket.userId!);

      // Emit read receipt to room members
      socket.to(roomId).emit('messageRead', {
        messageId,
        userId: socket.userId,
        username: socket.username,
        readAt: new Date(),
      });

    } catch (error) {
      logger.error('Error in messageRead event:', error);
      socket.emit('error', { message: 'Failed to mark message as read' });
    }
  });

  // Handle user online status
  socket.on('updateStatus', async (data: { status: 'online' | 'offline' | 'away' }) => {
    try {
      // Rate limit check
      if (!socketRateLimiter.checkUser(socket.userId!, 'updateStatus', SOCKET_RATE_LIMITS.updateStatus)) {
        socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
        return;
      }

      const { status } = data;

      if (!['online', 'offline', 'away'].includes(status)) {
        socket.emit('error', { message: 'Invalid status' });
        return;
      }

      // Update user status in database
      await User.findByIdAndUpdate(socket.userId, {
        isOnline: status === 'online',
        lastSeen: new Date(),
      });

      // Broadcast status change to all connected clients
      socket.broadcast.emit('userStatusChanged', {
        userId: socket.userId,
        username: socket.username,
        status,
        timestamp: new Date(),
      });

      logger.info(`User ${socket.username} status changed to ${status}`);
    } catch (error) {
      logger.error('Error in updateStatus event:', error);
      socket.emit('error', { message: 'Failed to update status' });
    }
  });

  // Handle disconnect
  socket.on('disconnect', async (reason) => {
    try {
      // Decrement socket count and update status
      if (socket.userId) {
        // Atomically decrement socket count
        const user = await User.findByIdAndUpdate(
          socket.userId,
          {
            $inc: { activeSocketCount: -1 },
            lastSeen: new Date(),
          },
          { new: true }
        );

        // Only set offline if no active sockets remain
        if (user && user.activeSocketCount <= 0) {
          await User.findByIdAndUpdate(socket.userId, {
            isOnline: false,
            activeSocketCount: 0, // Ensure it doesn't go negative
          });

          // Broadcast user went offline
          socket.broadcast.emit('userStatusChanged', {
            userId: socket.userId,
            username: socket.username,
            status: 'offline',
            timestamp: new Date(),
          });
        }
      }

      logger.info(`User ${socket.username} disconnected: ${reason}`);
    } catch (error) {
      logger.error('Error handling disconnect:', error);
    }
  });

  // Handle errors
  socket.on('error', (error) => {
    logger.error(`Socket error for user ${socket.username}:`, error);
  });
};