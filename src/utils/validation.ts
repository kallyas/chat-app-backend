import Joi from 'joi';
import mongoose from 'mongoose';

export const registerSchema = Joi.object({
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Please provide a valid email',
      'any.required': 'Email is required',
    }),
  username: Joi.string()
    .min(3)
    .max(30)
    .pattern(/^[a-zA-Z0-9_-]+$/)
    .required()
    .messages({
      'string.min': 'Username must be at least 3 characters',
      'string.max': 'Username cannot exceed 30 characters',
      'string.pattern.base': 'Username can only contain letters, numbers, underscores, and hyphens',
      'any.required': 'Username is required',
    }),
  password: Joi.string()
    .min(6)
    .required()
    .messages({
      'string.min': 'Password must be at least 6 characters',
      'any.required': 'Password is required',
    }),
  profilePic: Joi.string().uri().allow(''),
});

export const loginSchema = Joi.object({
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Please provide a valid email',
      'any.required': 'Email is required',
    }),
  password: Joi.string()
    .required()
    .messages({
      'any.required': 'Password is required',
    }),
});

export const updateUserSchema = Joi.object({
  username: Joi.string()
    .min(3)
    .max(30)
    .pattern(/^[a-zA-Z0-9_-]+$/),
  profilePic: Joi.string().uri().allow(''),
  password: Joi.string().min(6),
});

export const createChatRoomSchema = Joi.object({
  name: Joi.string()
    .max(50)
    .trim(),
  type: Joi.string()
    .valid('private', 'group')
    .required(),
  participants: Joi.array()
    .items(Joi.string().custom((value: string, helpers) => {
      if (!mongoose.Types.ObjectId.isValid(value)) {
        return helpers.error('any.invalid');
      }
      return value;
    }))
    .min(1)
    .required(),
  description: Joi.string()
    .max(200)
    .trim()
    .allow(''),
});

export const sendMessageSchema = Joi.object({
  content: Joi.string()
    .max(2000)
    .required()
    .messages({
      'string.max': 'Message content cannot exceed 2000 characters',
      'any.required': 'Message content is required',
    }),
  type: Joi.string()
    .valid('text', 'image', 'file')
    .default('text'),
  replyTo: Joi.string().custom((value: string, helpers) => {
    if (value && !mongoose.Types.ObjectId.isValid(value)) {
      return helpers.error('any.invalid');
    }
    return value;
  }),
  metadata: Joi.object({
    fileName: Joi.string(),
    fileSize: Joi.number().positive(),
    mimeType: Joi.string(),
    imageWidth: Joi.number().positive(),
    imageHeight: Joi.number().positive(),
  }),
});

export const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sortBy: Joi.string().default('createdAt'),
  sortOrder: Joi.string().valid('asc', 'desc').default('desc'),
});

export const searchSchema = Joi.object({
  query: Joi.string()
    .min(1)
    .max(100)
    .required()
    .messages({
      'string.min': 'Search query must be at least 1 character',
      'string.max': 'Search query cannot exceed 100 characters',
      'any.required': 'Search query is required',
    }),
  type: Joi.string().valid('username', 'email', 'both').default('both'),
});

export const resetPasswordSchema = Joi.object({
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Please provide a valid email',
      'any.required': 'Email is required',
    }),
});

export const objectIdSchema = Joi.string().custom((value: string, helpers) => {
  if (!mongoose.Types.ObjectId.isValid(value)) {
    return helpers.error('any.invalid', { message: 'Invalid ID format' });
  }
  return value;
});