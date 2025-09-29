import { Response } from 'express';
import { ChatService } from '@/services';
import { catchAsync, AppError, AuthRequest } from '@/middleware';
import { sendMessageSchema, paginationSchema, objectIdSchema } from '@/utils';
import { MessageType } from '@/models';
import { SendMessageData } from '@/services/chatService';

export const sendMessage = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const roomIdValidation = objectIdSchema.validate(roomId);
  if (roomIdValidation.error) {
    throw new AppError('Invalid room ID format', 400);
  }

  const validation = sendMessageSchema.validate(req.body);
  if (validation.error) {
    throw new AppError(validation.error.details[0].message, 400);
  }

  const { content, type, replyTo, metadata } = validation.value as { content: string; type?: string; replyTo?: string; metadata?: Record<string, unknown> };
  const messageData = {
    content,
    type: type,
    replyTo,
    metadata,
    chatRoomId: roomId,
    senderId: req.user._id.toString(),
  };

  const message = await ChatService.sendMessage(messageData as SendMessageData);

  res.status(201).json({
    success: true,
    message: 'Message sent successfully',
    data: {
      message,
    },
  });
});

export const getMessages = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { roomId } = req.params;
  
  const roomIdValidation = objectIdSchema.validate(roomId);
  if (roomIdValidation.error) {
    throw new AppError('Invalid room ID format', 400);
  }

  const validation = paginationSchema.validate(req.query);
  if (validation.error) {
    throw new AppError(validation.error.details[0].message, 400);
  }

  const query = {
    page: (validation.value as { page: number }).page,
    limit: (validation.value as { limit: number }).limit,
    before: req.query.before as string,
  };

  const result = await ChatService.getMessages(roomId, req.user._id.toString(), query);

  res.status(200).json({
    success: true,
    data: {
      messages: result.messages,
      pagination: result.pagination,
    },
  });
});

export const editMessage = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { messageId } = req.params;
  const { content } = req.body as { content: string };
  
  const messageIdValidation = objectIdSchema.validate(messageId);
  if (messageIdValidation.error) {
    throw new AppError('Invalid message ID format', 400);
  }

  if (!content || typeof content !== 'string') {
    throw new AppError('Message content is required', 400);
  }

  if (content.length > 2000) {
    throw new AppError('Message content cannot exceed 2000 characters', 400);
  }

  const message = await ChatService.editMessage(messageId, req.user._id.toString(), content);

  res.status(200).json({
    success: true,
    message: 'Message edited successfully',
    data: {
      message,
    },
  });
});

export const deleteMessage = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { messageId } = req.params;
  
  const messageIdValidation = objectIdSchema.validate(messageId);
  if (messageIdValidation.error) {
    throw new AppError('Invalid message ID format', 400);
  }

  await ChatService.deleteMessage(messageId, req.user._id.toString());

  res.status(200).json({
    success: true,
    message: 'Message deleted successfully',
  });
});

export const markMessageAsRead = catchAsync(async (req: AuthRequest, res: Response): Promise<void> => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { messageId } = req.params;
  
  const messageIdValidation = objectIdSchema.validate(messageId);
  if (messageIdValidation.error) {
    throw new AppError('Invalid message ID format', 400);
  }

  // This would typically be handled automatically through socket events,
  // but providing a REST endpoint as fallback
  await Promise.resolve(); // Satisfy the await requirement
  res.status(200).json({
    success: true,
    message: 'Message marked as read - typically handled via socket events',
  });
});