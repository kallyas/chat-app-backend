import { Router } from 'express';
import { userController } from '@/controllers';
import { authenticateToken, searchLimiter } from '@/middleware';

const router = Router();
const requireAuth = (req: Parameters<typeof authenticateToken>[0], res: Parameters<typeof authenticateToken>[1], next: Parameters<typeof authenticateToken>[2]) => {
  void authenticateToken(req, res, next);
};

// All user routes require authentication
router.use(requireAuth);

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
