import {
  generateResetToken,
  sanitizeUser,
  isValidObjectId,
  toObjectId,
  formatError,
  getPaginationInfo,
  escapeRegex,
  truncateText,
  formatFileSize,
} from '@/utils/helpers';
import mongoose from 'mongoose';

describe('Helper Functions', () => {
  describe('generateResetToken', () => {
    it('should generate a reset token and hashed token', () => {
      const { token, hashedToken } = generateResetToken();

      expect(token).toHaveLength(64); // 32 bytes = 64 hex characters
      expect(hashedToken).toHaveLength(64); // SHA256 hash = 64 hex characters
      expect(token).not.toBe(hashedToken);
    });

    it('should generate different tokens each time', () => {
      const result1 = generateResetToken();
      const result2 = generateResetToken();

      expect(result1.token).not.toBe(result2.token);
      expect(result1.hashedToken).not.toBe(result2.hashedToken);
    });
  });

  describe('sanitizeUser', () => {
    it('should remove sensitive fields from user object', () => {
      const user = {
        _id: 'user123',
        email: 'test@example.com',
        username: 'testuser',
        password: 'hashedpassword',
        resetPasswordToken: 'token',
        resetPasswordExpire: new Date(),
        profilePic: 'pic.jpg',
      };

      const sanitized = sanitizeUser(user);

      expect(sanitized.password).toBeUndefined();
      expect(sanitized.resetPasswordToken).toBeUndefined();
      expect(sanitized.resetPasswordExpire).toBeUndefined();
      expect(sanitized.email).toBe(user.email);
      expect(sanitized.username).toBe(user.username);
      expect(sanitized.profilePic).toBe(user.profilePic);
    });
  });

  describe('isValidObjectId', () => {
    it('should return true for valid ObjectId strings', () => {
      const validId = new mongoose.Types.ObjectId().toString();
      expect(isValidObjectId(validId)).toBe(true);
    });

    it('should return false for invalid ObjectId strings', () => {
      expect(isValidObjectId('invalid')).toBe(false);
      expect(isValidObjectId('123')).toBe(false);
      expect(isValidObjectId('')).toBe(false);
    });
  });

  describe('toObjectId', () => {
    it('should convert string to ObjectId', () => {
      const idString = '507f1f77bcf86cd799439011';
      const objectId = toObjectId(idString);

      expect(objectId).toBeInstanceOf(mongoose.Types.ObjectId);
      expect(objectId.toString()).toBe(idString);
    });
  });

  describe('formatError', () => {
    it('should format validation errors', () => {
      const validationError = {
        name: 'ValidationError',
        errors: {
          email: { message: 'Email is required' },
          password: { message: 'Password is too short' },
        },
      };

      const formatted = formatError(validationError);
      expect(formatted).toBe('Email is required. Password is too short');
    });

    it('should format duplicate key errors', () => {
      const duplicateError = {
        code: 11000,
        keyValue: { email: 'test@example.com' },
      };

      const formatted = formatError(duplicateError);
      expect(formatted).toBe('email already exists');
    });

    it('should return original message for other errors', () => {
      const genericError = {
        message: 'Something went wrong',
      };

      const formatted = formatError(genericError);
      expect(formatted).toBe('Something went wrong');
    });
  });

  describe('getPaginationInfo', () => {
    it('should calculate pagination info correctly', () => {
      const page = 2;
      const limit = 10;
      const total = 25;

      const pagination = getPaginationInfo(page, limit, total);

      expect(pagination.currentPage).toBe(2);
      expect(pagination.totalPages).toBe(3);
      expect(pagination.totalItems).toBe(25);
      expect(pagination.itemsPerPage).toBe(10);
      expect(pagination.hasNextPage).toBe(true);
      expect(pagination.hasPrevPage).toBe(true);
      expect(pagination.nextPage).toBe(3);
      expect(pagination.prevPage).toBe(1);
    });

    it('should handle first page correctly', () => {
      const pagination = getPaginationInfo(1, 10, 25);

      expect(pagination.hasPrevPage).toBe(false);
      expect(pagination.prevPage).toBe(null);
      expect(pagination.hasNextPage).toBe(true);
    });

    it('should handle last page correctly', () => {
      const pagination = getPaginationInfo(3, 10, 25);

      expect(pagination.hasNextPage).toBe(false);
      expect(pagination.nextPage).toBe(null);
      expect(pagination.hasPrevPage).toBe(true);
    });
  });

  describe('escapeRegex', () => {
    it('should escape special regex characters', () => {
      const input = 'test.email+123@example.com';
      const escaped = escapeRegex(input);

      expect(escaped).toBe('test\\.email\\+123@example\\.com');
    });

    it('should handle empty string', () => {
      const escaped = escapeRegex('');
      expect(escaped).toBe('');
    });
  });

  describe('truncateText', () => {
    it('should truncate text longer than max length', () => {
      const text = 'This is a very long text that should be truncated';
      const truncated = truncateText(text, 20);

      expect(truncated).toBe('This is a very long ...');
      expect(truncated.length).toBe(23); // 20 + '...'
    });

    it('should not truncate text shorter than max length', () => {
      const text = 'Short text';
      const truncated = truncateText(text, 20);

      expect(truncated).toBe(text);
    });

    it('should handle exact length', () => {
      const text = 'Exactly twenty chars';
      const truncated = truncateText(text, 20);

      expect(truncated).toBe(text);
    });
  });

  describe('formatFileSize', () => {
    it('should format bytes correctly', () => {
      expect(formatFileSize(0)).toBe('0 Bytes');
      expect(formatFileSize(512)).toBe('512 Bytes');
    });

    it('should format KB correctly', () => {
      expect(formatFileSize(1024)).toBe('1 KB');
      expect(formatFileSize(1536)).toBe('1.5 KB');
    });

    it('should format MB correctly', () => {
      expect(formatFileSize(1024 * 1024)).toBe('1 MB');
      expect(formatFileSize(1024 * 1024 * 2.5)).toBe('2.5 MB');
    });

    it('should format GB correctly', () => {
      expect(formatFileSize(1024 * 1024 * 1024)).toBe('1 GB');
    });
  });
});
