import { Response } from 'express';
import { ChatService } from '@/services';
import { catchAsync, AppError, AuthRequest } from '@/middleware';
import { createChatRoomSchema, objectIdSchema } from '@/utils';

export const createChatRoom = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const validation = createChatRoomSchema.validate(req.body);
  
  if (validation.error) {
    throw new AppError(validation.error.details[0].message, 400);
  }

  const chatRoomData = {
    ...(validation.value as { name?: string; type: string; participants: string[]; description?: string }),
    type: validation.value.type as import('@/models').ChatRoomType,
    createdBy: req.user._id.toString(),
  };

  const chatRoom = await ChatService.createChatRoom(chatRoomData);

  res.status(201).json({
    success: true,
    message: 'Chat room created successfully',
    data: {
      chatRoom,
    },
  });
});

export const getUserChatRooms = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const chatRooms = await ChatService.getUserChatRooms(req.user._id.toString());

  res.status(200).json({
    success: true,
    data: {
      chatRooms,
      count: chatRooms.length,
    },
  });
});

export const getChatRoomById = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const { error } = objectIdSchema.validate(roomId);
  if (error) {
    throw new AppError('Invalid room ID format', 400);
  }

  const chatRoom = await ChatService.getChatRoomById(roomId, req.user._id.toString());

  res.status(200).json({
    success: true,
    data: {
      chatRoom,
    },
  });
});

export const joinChatRoom = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const { error } = objectIdSchema.validate(roomId);
  if (error) {
    throw new AppError('Invalid room ID format', 400);
  }

  const chatRoom = await ChatService.joinChatRoom(roomId, req.user._id.toString());

  res.status(200).json({
    success: true,
    message: 'Joined chat room successfully',
    data: {
      chatRoom,
    },
  });
});

export const leaveChatRoom = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const { error } = objectIdSchema.validate(roomId);
  if (error) {
    throw new AppError('Invalid room ID format', 400);
  }

  await ChatService.leaveChatRoom(roomId, req.user._id.toString());

  res.status(200).json({
    success: true,
    message: 'Left chat room successfully',
  });
});

export const updateChatRoom = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const { error } = objectIdSchema.validate(roomId);
  if (error) {
    throw new AppError('Invalid room ID format', 400);
  }

  const chatRoom = await ChatService.updateChatRoom(roomId, req.user._id.toString(), req.body as Partial<import('@/models').IChatRoom>);

  res.status(200).json({
    success: true,
    message: 'Chat room updated successfully',
    data: {
      chatRoom,
    },
  });
});

export const deleteChatRoom = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const { error } = objectIdSchema.validate(roomId);
  if (error) {
    throw new AppError('Invalid room ID format', 400);
  }

  await ChatService.deleteChatRoom(roomId, req.user._id.toString());

  res.status(200).json({
    success: true,
    message: 'Chat room deleted successfully',
  });
});

export const getUnreadCount = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const { error } = objectIdSchema.validate(roomId);
  if (error) {
    throw new AppError('Invalid room ID format', 400);
  }

  const count = await ChatService.getUnreadMessageCount(roomId, req.user._id.toString());

  res.status(200).json({
    success: true,
    data: {
      unreadCount: count,
    },
  });
});

export const markMessagesAsRead = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const { error } = objectIdSchema.validate(roomId);
  if (error) {
    throw new AppError('Invalid room ID format', 400);
  }

  await ChatService.markMessagesAsRead(roomId, req.user._id.toString());

  res.status(200).json({
    success: true,
    message: 'Messages marked as read',
  });
});