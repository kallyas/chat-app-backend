import { Router } from 'express';
import { authController } from '@/controllers';
import { authenticateToken, authLimiter } from '@/middleware';

const router = Router();
const requireAuth = (
  req: Parameters<typeof authenticateToken>[0],
  res: Parameters<typeof authenticateToken>[1],
  next: Parameters<typeof authenticateToken>[2]
) => {
  void authenticateToken(req, res, next);
};

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
router.post('/logout', requireAuth, authController.logout);
router.get('/me', requireAuth, authController.getMe);
router.put('/me', requireAuth, authController.updateProfile);

export default router;
