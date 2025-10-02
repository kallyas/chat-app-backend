/**
 * Central types definition file for the Chat App Backend
 * 
 * This file consolidates all TypeScript interfaces and types to improve
 * type consistency and maintainability across the project.
 */

import { Request } from 'express';
import { ChatRoomType, MessageType, IUser } from '@/models';

// ============================================================================
// AUTH DOMAIN TYPES
// ============================================================================

/**
 * User registration data interface
 */
export interface RegisterUserData {
  /** User's email address (must be unique) */
  email: string;
  /** User's username (must be unique) */
  username: string;
  /** User's password (minimum 8 characters) */
  password: string;
  /** Optional profile picture URL */
  profilePic?: string;
}

/**
 * User login data interface
 */
export interface LoginUserData {
  /** User's email address */
  email: string;
  /** User's password */
  password: string;
}

/**
 * Extended Express Request interface that includes authenticated user
 */
export interface AuthRequest extends Request {
  /** Authenticated user object (set by auth middleware) */
  user?: IUser;
}

/**
 * JWT token payload structure
 */
export interface JWTPayload {
  /** User's unique identifier */
  id: string;
  /** User's email address */
  email: string;
  /** User's username */
  username: string;
  /** Token version for invalidation */
  tokenVersion?: number;
  /** Token issued at timestamp (seconds) */
  iat?: number;
  /** Token expiration timestamp (seconds) */
  exp?: number;
}

// ============================================================================
// CHAT DOMAIN TYPES
// ============================================================================

/**
 * Data required to create a new chat room
 */
export interface CreateChatRoomData {
  /** Chat room name (required for group chats, optional for private) */
  name?: string | undefined;
  /** Type of chat room (private or group) */
  type: ChatRoomType;
  /** Array of participant user IDs */
  participants: string[];
  /** Optional room description */
  description?: string | undefined;
  /** User ID of the room creator */
  createdBy: string;
}

/**
 * Data required to send a message
 */
export interface SendMessageData {
  /** Target chat room ID */
  chatRoomId: string;
  /** Sender's user ID */
  senderId: string;
  /** Message content */
  content: string;
  /** Type of message (text, image, file, etc.) */
  type?: MessageType | undefined;
  /** ID of message being replied to (optional) */
  replyTo?: string | undefined;
  /** Additional message metadata for files/images */
  metadata?: {
    /** Original file name */
    fileName?: string;
    /** File size in bytes */
    fileSize?: number;
    /** MIME type of the file */
    mimeType?: string;
    /** Image width in pixels */
    imageWidth?: number;
    /** Image height in pixels */
    imageHeight?: number;
  } | undefined;
}

/**
 * Query parameters for retrieving messages
 */
export interface GetMessagesQuery {
  /** Page number for pagination (default: 1) */
  page?: number;
  /** Number of messages per page (default: 20) */
  limit?: number;
  /** Message ID to fetch messages before (for cursor-based pagination) */
  before?: string;
}

// ============================================================================
// API RESPONSE TYPES
// ============================================================================

/**
 * Standard API success response structure
 */
export interface ApiResponse<T = unknown> {
  /** Indicates if the request was successful */
  success: true;
  /** Human-readable success message */
  message: string;
  /** Response data payload */
  data: T;
}

/**
 * Standard API error response structure
 */
export interface ApiErrorResponse {
  /** Indicates the request failed */
  success: false;
  /** Human-readable error message */
  message: string;
  /** Optional error details */
  errors?: string[];
  /** Error code for client handling */
  code?: string;
}

/**
 * Pagination information for paginated responses
 */
export interface PaginationInfo {
  /** Current page number */
  page: number;
  /** Number of items per page */
  limit: number;
  /** Total number of items */
  total: number;
  /** Total number of pages */
  pages: number;
  /** Whether there is a next page */
  hasNext: boolean;
  /** Whether there is a previous page */
  hasPrev: boolean;
}

/**
 * Paginated response wrapper
 */
export interface PaginatedResponse<T> {
  /** Array of items for current page */
  items: T[];
  /** Pagination metadata */
  pagination: PaginationInfo;
}

// ============================================================================
// VALIDATION TYPES
// ============================================================================

/**
 * Joi validation result type
 */
export interface ValidationResult<T> {
  /** Validation error details */
  error?: {
    /** Array of validation error details */
    details: Array<{
      /** Error message */
      message: string;
      /** Field path that failed validation */
      path: (string | number)[];
      /** Field type */
      type: string;
    }>;
  };
  /** Validated and sanitized value */
  value: T;
}

/**
 * Common request body validation interfaces
 */
export interface ValidatedRequestBody<T> {
  /** Indicates if validation passed */
  isValid: boolean;
  /** Validation errors (if any) */
  errors?: string[];
  /** Validated data */
  data?: T;
}

// ============================================================================
// UTILITY TYPES
// ============================================================================

/**
 * Make all properties of T optional recursively
 */
export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

/**
 * Extract the keys of T that are of type U
 */
export type KeysOfType<T, U> = {
  [K in keyof T]: T[K] extends U ? K : never;
}[keyof T];

/**
 * MongoDB ObjectId string type alias
 */
export type ObjectIdString = string;

/**
 * Timestamp type (can be Date or ISO string)
 */
export type Timestamp = Date | string;