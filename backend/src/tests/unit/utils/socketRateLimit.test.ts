import { Socket } from 'socket.io';
import { SocketRateLimiter, RateLimitConfig } from '@/utils/socketRateLimit';

jest.mock('@/config/logger', () => ({
  logger: {
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
  },
}));

describe('SocketRateLimiter', () => {
  let rateLimiter: SocketRateLimiter;
  let mockSocket: Partial<Socket>;

  beforeEach(() => {
    rateLimiter = new SocketRateLimiter(false); // Disable auto cleanup for tests
    mockSocket = {
      id: 'socket-123',
      disconnect: jest.fn(),
    };
  });

  afterEach(() => {
    rateLimiter.destroy();
  });

  describe('check', () => {
    it('should allow requests within rate limit', () => {
      const config: RateLimitConfig = {
        maxRequests: 5,
        windowMs: 60000,
      };

      for (let i = 0; i < 5; i++) {
        const allowed = rateLimiter.check(mockSocket as Socket, 'test-event', config);
        expect(allowed).toBe(true);
      }
    });

    it('should block requests exceeding rate limit', () => {
      const config: RateLimitConfig = {
        maxRequests: 3,
        windowMs: 60000,
      };

      // Make 3 allowed requests
      for (let i = 0; i < 3; i++) {
        rateLimiter.check(mockSocket as Socket, 'test-event', config);
      }

      // 4th request should be blocked
      const allowed = rateLimiter.check(mockSocket as Socket, 'test-event', config);
      expect(allowed).toBe(false);
    });

    it('should reset rate limit after window expires', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 100, // 100ms window
      };

      // Use up the limit
      rateLimiter.check(mockSocket as Socket, 'test-event', config);
      rateLimiter.check(mockSocket as Socket, 'test-event', config);

      // Should be blocked
      expect(rateLimiter.check(mockSocket as Socket, 'test-event', config)).toBe(false);

      // Wait for window to expire
      return new Promise(resolve => {
        setTimeout(() => {
          // Should be allowed again after window reset
          const allowed = rateLimiter.check(mockSocket as Socket, 'test-event', config);
          expect(allowed).toBe(true);
          resolve(undefined);
        }, 150);
      });
    });

    it('should disconnect socket after max violations', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 60000,
        maxViolations: 3,
      };

      // Use up the limit
      rateLimiter.check(mockSocket as Socket, 'test-event', config);
      rateLimiter.check(mockSocket as Socket, 'test-event', config);

      // Make 3 violations
      for (let i = 0; i < 3; i++) {
        rateLimiter.check(mockSocket as Socket, 'test-event', config);
      }

      expect(mockSocket.disconnect).toHaveBeenCalledWith(true);
    });

    it('should track different events separately', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 60000,
      };

      rateLimiter.check(mockSocket as Socket, 'event1', config);
      rateLimiter.check(mockSocket as Socket, 'event1', config);

      // event1 should be blocked
      expect(rateLimiter.check(mockSocket as Socket, 'event1', config)).toBe(false);

      // event2 should still be allowed
      expect(rateLimiter.check(mockSocket as Socket, 'event2', config)).toBe(true);
    });
  });

  describe('checkUser', () => {
    it('should allow requests within rate limit for user', () => {
      const config: RateLimitConfig = {
        maxRequests: 5,
        windowMs: 60000,
      };

      for (let i = 0; i < 5; i++) {
        const allowed = rateLimiter.checkUser('user-123', 'test-event', config);
        expect(allowed).toBe(true);
      }
    });

    it('should block requests exceeding rate limit for user', () => {
      const config: RateLimitConfig = {
        maxRequests: 3,
        windowMs: 60000,
      };

      // Make 3 allowed requests
      for (let i = 0; i < 3; i++) {
        rateLimiter.checkUser('user-123', 'test-event', config);
      }

      // 4th request should be blocked
      const allowed = rateLimiter.checkUser('user-123', 'test-event', config);
      expect(allowed).toBe(false);
    });

    it('should track different users separately', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 60000,
      };

      rateLimiter.checkUser('user-123', 'test-event', config);
      rateLimiter.checkUser('user-123', 'test-event', config);

      // user-123 should be blocked
      expect(rateLimiter.checkUser('user-123', 'test-event', config)).toBe(false);

      // user-456 should still be allowed
      expect(rateLimiter.checkUser('user-456', 'test-event', config)).toBe(true);
    });
  });

  describe('getRemaining', () => {
    it('should return correct remaining requests', () => {
      const config: RateLimitConfig = {
        maxRequests: 5,
        windowMs: 60000,
      };

      rateLimiter.check(mockSocket as Socket, 'test-event', config);
      rateLimiter.check(mockSocket as Socket, 'test-event', config);

      const remaining = rateLimiter.getRemaining('socket-123', 'test-event', 5);
      expect(remaining).toBe(3);
    });

    it('should return max requests when no limit exists', () => {
      const remaining = rateLimiter.getRemaining('socket-123', 'test-event', 10);
      expect(remaining).toBe(10);
    });

    it('should return 0 when limit exceeded', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 60000,
      };

      rateLimiter.check(mockSocket as Socket, 'test-event', config);
      rateLimiter.check(mockSocket as Socket, 'test-event', config);
      rateLimiter.check(mockSocket as Socket, 'test-event', config);

      const remaining = rateLimiter.getRemaining('socket-123', 'test-event', 2);
      expect(remaining).toBe(0);
    });
  });

  describe('clearSocket', () => {
    it('should clear all rate limits for a socket', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 60000,
      };

      rateLimiter.check(mockSocket as Socket, 'event1', config);
      rateLimiter.check(mockSocket as Socket, 'event2', config);

      rateLimiter.clearSocket('socket-123');

      // Should be reset
      const remaining1 = rateLimiter.getRemaining('socket-123', 'event1', 2);
      const remaining2 = rateLimiter.getRemaining('socket-123', 'event2', 2);

      expect(remaining1).toBe(2);
      expect(remaining2).toBe(2);
    });
  });

  describe('clearUser', () => {
    it('should clear all rate limits for a user', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 60000,
      };

      rateLimiter.checkUser('user-123', 'event1', config);
      rateLimiter.checkUser('user-123', 'event2', config);

      rateLimiter.clearUser('user-123');

      // Should be reset
      expect(rateLimiter.checkUser('user-123', 'event1', config)).toBe(true);
      expect(rateLimiter.checkUser('user-123', 'event2', config)).toBe(true);
    });
  });

  describe('destroy', () => {
    it('should clear all limits and cleanup interval', () => {
      const config: RateLimitConfig = {
        maxRequests: 2,
        windowMs: 60000,
      };

      rateLimiter.check(mockSocket as Socket, 'test-event', config);
      rateLimiter.destroy();

      // After destroy, new checks should work with fresh state
      expect(rateLimiter.check(mockSocket as Socket, 'test-event', config)).toBe(true);
    });
  });
});
