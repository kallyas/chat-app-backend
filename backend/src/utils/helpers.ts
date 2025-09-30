import crypto from 'crypto';
import mongoose from 'mongoose';

export const generateResetToken = (): { token: string; hashedToken: string } => {
  const resetToken = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex');
  
  return { token: resetToken, hashedToken };
};

export const sanitizeUser = (user: Record<string, unknown>) => {
  const sanitizedUser = { ...user };
  delete sanitizedUser.password;
  delete sanitizedUser.resetPasswordToken;
  delete sanitizedUser.resetPasswordExpire;
  return sanitizedUser;
};

export const generateRoomName = (participants: string[]): string => {
  return participants.sort().join('-');
};

export const isValidObjectId = (id: string): boolean => {
  return mongoose.Types.ObjectId.isValid(id);
};

export const toObjectId = (id: string): mongoose.Types.ObjectId => {
  return new mongoose.Types.ObjectId(id);
};

export const formatError = (error: Record<string, unknown>): string => {
  if (error.name === 'ValidationError') {
    const errors = Object.values(error.errors as Record<string, { message: string }>).map((err) => err.message);
    return errors.join('. ');
  }
  
  if (error.code === 11000) {
    const field = Object.keys(error.keyValue as Record<string, unknown>)[0];
    return `${field} already exists`;
  }
  
  return (error.message as string) || 'An error occurred';
};

export const getPaginationInfo = (page: number, limit: number, total: number) => {
  const totalPages = Math.ceil(total / limit);
  const hasNextPage = page < totalPages;
  const hasPrevPage = page > 1;
  
  return {
    currentPage: page,
    totalPages,
    totalItems: total,
    itemsPerPage: limit,
    hasNextPage,
    hasPrevPage,
    nextPage: hasNextPage ? page + 1 : null,
    prevPage: hasPrevPage ? page - 1 : null,
  };
};

export const generateCacheKey = (...parts: string[]): string => {
  return parts.join(':');
};

export const isProduction = (): boolean => {
  return process.env.NODE_ENV === 'production';
};

export const isDevelopment = (): boolean => {
  return process.env.NODE_ENV === 'development';
};

export const delay = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

export const escapeRegex = (text: string): string => {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
};

export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
};

export const getFileExtension = (filename: string): string => {
  return filename.split('.').pop()?.toLowerCase() || '';
};

export const formatFileSize = (bytes: number): string => {
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  if (bytes === 0) return '0 Bytes';
  
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
};

export const generateRandomString = (length: number): string => {
  return crypto.randomBytes(Math.ceil(length / 2)).toString('hex').slice(0, length);
};