import { Router } from 'express';
import { chatroomController, messageController } from '@/controllers';
import { authenticateToken, messageLimiter } from '@/middleware';

const router = Router();

// All chatroom routes require authentication
router.use(authenticateToken);

// Chat room CRUD operations
router.post('/', chatroomController.createChatRoom);
router.get('/', chatroomController.getUserChatRooms);
router.get('/:roomId', chatroomController.getChatRoomById);
router.put('/:roomId', chatroomController.updateChatRoom);
router.delete('/:roomId', chatroomController.deleteChatRoom);

// Join/Leave chat room
router.post('/:roomId/join', chatroomController.joinChatRoom);
router.post('/:roomId/leave', chatroomController.leaveChatRoom);

// Message operations within chat rooms
router.post('/:roomId/messages', messageLimiter, messageController.sendMessage);
router.get('/:roomId/messages', messageController.getMessages);

// Message read status
router.post('/:roomId/read', chatroomController.markMessagesAsRead);
router.get('/:roomId/unread-count', chatroomController.getUnreadCount);

// Individual message operations
router.put('/messages/:messageId', messageController.editMessage);
router.delete('/messages/:messageId', messageController.deleteMessage);
router.post('/messages/:messageId/read', messageController.markMessageAsRead);

export default router;