import mongoose from 'mongoose';
import { database } from '@/config/database';

jest.mock('@/config/logger', () => ({
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
  },
}));

describe('Database', () => {
  afterEach(() => {
    jest.clearAllMocks();
    jest.restoreAllMocks();
    (mongoose.connection as unknown as { _readyState: number })._readyState = 1;
  });

  describe('getInstance', () => {
    it('should return a singleton instance', () => {
      const instance1 = database;
      const instance2 = database;
      expect(instance1).toBe(instance2);
    });
  });

  describe('connect', () => {
    it('should connect successfully with provided URI', async () => {
      const mockConnect = jest
        .spyOn(mongoose, 'connect')
        .mockResolvedValue(mongoose);

      await database.connect();

      expect(mockConnect).toHaveBeenCalledWith(
        expect.stringContaining('mongodb://')
      );
      mockConnect.mockRestore();
    });
  });

  describe('disconnect', () => {
    it('should disconnect from MongoDB', async () => {
      const mockDisconnect = jest
        .spyOn(mongoose, 'disconnect')
        .mockResolvedValue();

      await database.disconnect();

      expect(mockDisconnect).toHaveBeenCalled();
      mockDisconnect.mockRestore();
    });
  });

  describe('health state', () => {
    it('should report healthy when mongoose is connected', () => {
      (mongoose.connection as unknown as { _readyState: number })._readyState =
        1;

      expect(database.isHealthy()).toBe(true);
      expect(database.getStatus()).toBe('connected');
    });

    it('should report non-healthy state when mongoose is disconnected', () => {
      (mongoose.connection as unknown as { _readyState: number })._readyState =
        0;

      expect(database.isHealthy()).toBe(false);
      expect(database.getStatus()).toBe('disconnected');
    });
  });
});
