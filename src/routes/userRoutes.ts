import { Router } from 'express';
import { userController } from '@/controllers';
import { authenticateToken, searchLimiter } from '@/middleware';

const router = Router();

// All user routes require authentication
router.use(authenticateToken);

// User profile routes
router.get('/me', userController.getProfile);
router.put('/me', userController.updateProfile);

// User search and discovery
router.get('/search', searchLimiter, userController.searchUsers);
router.get('/online', userController.getOnlineUsers);

// Get specific user by ID
router.get('/:userId', userController.getUserById);

// Update online status
router.put('/status', userController.updateOnlineStatus);

export default router;