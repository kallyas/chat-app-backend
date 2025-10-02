import { Router } from 'express';
import { authController } from '@/controllers';
import { authenticateToken, authLimiter } from '@/middleware';

const router = Router();

// Public routes
router.post('/register', authLimiter, authController.register);
router.post('/login', authLimiter, authController.login);
router.post(
  '/reset-password',
  authLimiter,
  authController.initiatePasswordReset
);
router.post(
  '/reset-password/:token',
  authLimiter,
  authController.resetPassword
);
router.post('/refresh-token', authController.refreshToken);

// Protected routes
router.post('/logout', authenticateToken, authController.logout);
router.get('/me', authenticateToken, authController.getMe);
router.put('/me', authenticateToken, authController.updateProfile);

export default router;
