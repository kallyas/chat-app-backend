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
      const mockConnect = jest.spyOn(mongoose, 'connect').mockResolvedValue(mongoose as any);

      await database.connect();

      expect(mockConnect).toHaveBeenCalledWith(process.env.MONGODB_URI);
      mockConnect.mockRestore();
    });
  });

  describe('disconnect', () => {
    it('should disconnect from MongoDB', async () => {
      const mockDisconnect = jest.spyOn(mongoose, 'disconnect').mockResolvedValue();

      await database.disconnect();

      expect(mockDisconnect).toHaveBeenCalled();
      mockDisconnect.mockRestore();
    });
  });
});
