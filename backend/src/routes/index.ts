import { Router } from 'express';
import authRoutes from './authRoutes';
import userRoutes from './userRoutes';
import chatroomRoutes from './chatroomRoutes';

const router = Router();

// API routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/chatrooms', chatroomRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Chat API is running',
    timestamp: new Date().toISOString(),
  });
});

export default router;
