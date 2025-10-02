import { Socket } from 'socket.io';
import { logger } from '@/config/logger';

interface RateLimitInfo {
  count: number;
  resetAt: number;
  violations: number;
}

export interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
  maxViolations?: number; // Number of violations before disconnecting
}

export class SocketRateLimiter {
  private limits = new Map<string, RateLimitInfo>();
  private cleanupInterval?: NodeJS.Timeout;

  constructor(enableAutoCleanup: boolean = true) {
    // Clean up expired entries every 5 minutes (optional for testing)
    if (enableAutoCleanup) {
      this.cleanupInterval = setInterval(
        () => {
          this.cleanup();
        },
        5 * 60 * 1000
      );
    }
  }

  /**
   * Check if a socket event is within rate limit
   * @param socket - The socket instance
   * @param event - The event name
   * @param config - Rate limit configuration
   * @returns true if allowed, false if rate limited
   */
  check(socket: Socket, event: string, config: RateLimitConfig): boolean {
    const socketId = socket.id;
    const key = `${socketId}:${event}`;
    const now = Date.now();
    const limit = this.limits.get(key);

    // If no limit exists or window has expired, create new limit
    if (!limit || now > limit.resetAt) {
      this.limits.set(key, {
        count: 1,
        resetAt: now + config.windowMs,
        violations: 0,
      });
      return true;
    }

    // If limit exceeded
    if (limit.count >= config.maxRequests) {
      limit.violations++;

      logger.warn(
        `Rate limit exceeded for socket ${socketId} on event '${event}': ${limit.count}/${config.maxRequests} requests in window`
      );

      // Disconnect socket if too many violations
      if (config.maxViolations && limit.violations >= config.maxViolations) {
        logger.error(
          `Socket ${socketId} exceeded violation threshold (${limit.violations}). Disconnecting.`
        );
        socket.disconnect(true);
      }

      return false;
    }

    // Increment count
    limit.count++;
    return true;
  }

  /**
   * Check rate limit for a user ID (persists across socket reconnections)
   * @param userId - The user ID
   * @param event - The event name
   * @param config - Rate limit configuration
   * @returns true if allowed, false if rate limited
   */
  checkUser(userId: string, event: string, config: RateLimitConfig): boolean {
    const key = `user:${userId}:${event}`;
    const now = Date.now();
    const limit = this.limits.get(key);

    if (!limit || now > limit.resetAt) {
      this.limits.set(key, {
        count: 1,
        resetAt: now + config.windowMs,
        violations: 0,
      });
      return true;
    }

    if (limit.count >= config.maxRequests) {
      limit.violations++;
      logger.warn(
        `Rate limit exceeded for user ${userId} on event '${event}': ${limit.count}/${config.maxRequests} requests in window`
      );
      return false;
    }

    limit.count++;
    return true;
  }

  /**
   * Get remaining requests for a socket/event combination
   */
  getRemaining(socketId: string, event: string, maxRequests: number): number {
    const key = `${socketId}:${event}`;
    const limit = this.limits.get(key);

    if (!limit || Date.now() > limit.resetAt) {
      return maxRequests;
    }

    return Math.max(0, maxRequests - limit.count);
  }

  /**
   * Clean up expired rate limit entries
   */
  private cleanup(): void {
    const now = Date.now();
    let cleaned = 0;

    for (const [key, limit] of this.limits.entries()) {
      if (now > limit.resetAt) {
        this.limits.delete(key);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      logger.debug(`Cleaned up ${cleaned} expired rate limit entries`);
    }
  }

  /**
   * Clear all rate limit data for a specific socket
   */
  clearSocket(socketId: string): void {
    for (const key of this.limits.keys()) {
      if (key.startsWith(`${socketId}:`)) {
        this.limits.delete(key);
      }
    }
  }

  /**
   * Clear all rate limit data for a specific user
   */
  clearUser(userId: string): void {
    for (const key of this.limits.keys()) {
      if (key.startsWith(`user:${userId}:`)) {
        this.limits.delete(key);
      }
    }
  }

  /**
   * Destroy the rate limiter and cleanup interval
   */
  destroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
    this.limits.clear();
  }
}

// Singleton instance - disable auto cleanup in test environment
export const socketRateLimiter = new SocketRateLimiter(
  process.env.NODE_ENV !== 'test'
);

// Recommended rate limit configurations
export const SOCKET_RATE_LIMITS = {
  sendMessage: { maxRequests: 30, windowMs: 60000, maxViolations: 3 }, // 30/minute
  typing: { maxRequests: 10, windowMs: 60000, maxViolations: 5 }, // 10/minute
  stopTyping: { maxRequests: 10, windowMs: 60000, maxViolations: 5 }, // 10/minute
  joinRoom: { maxRequests: 20, windowMs: 60000, maxViolations: 3 }, // 20/minute
  leaveRoom: { maxRequests: 20, windowMs: 60000, maxViolations: 3 }, // 20/minute
  updateStatus: { maxRequests: 5, windowMs: 60000, maxViolations: 3 }, // 5/minute
  messageRead: { maxRequests: 60, windowMs: 60000, maxViolations: 5 }, // 60/minute
};
