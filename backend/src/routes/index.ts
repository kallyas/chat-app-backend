import { Router } from 'express';
import authRoutes from './authRoutes';
import userRoutes from './userRoutes';
import chatroomRoutes from './chatroomRoutes';
import { database } from '@/config/database';
import { runtimeState } from '@/config/runtime';

const router = Router();

const buildHealthPayload = () => {
  const uptimeMs = runtimeState.getUptimeMs();

  return {
    success: true,
    status:
      database.isHealthy() && !runtimeState.isShuttingDown()
        ? 'ok'
        : 'degraded',
    timestamp: new Date().toISOString(),
    uptimeMs,
    services: {
      database: {
        healthy: database.isHealthy(),
        status: database.getStatus(),
      },
    },
    lifecycle: {
      shuttingDown: runtimeState.isShuttingDown(),
      startedAt: new Date(runtimeState.getStartedAt()).toISOString(),
    },
  };
};

// API routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/chatrooms', chatroomRoutes);

// Liveness and health endpoints for infrastructure checks
router.get('/health/live', (_req, res) => {
  res.status(200).json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

router.get('/health', (req, res) => {
  res.status(200).json(buildHealthPayload());
});

router.get('/health/ready', (_req, res) => {
  const ready = database.isHealthy() && !runtimeState.isShuttingDown();

  res.status(ready ? 200 : 503).json({
    ...buildHealthPayload(),
    status: ready ? 'ready' : 'not_ready',
  });
});

export default router;
