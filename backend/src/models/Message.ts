import mongoose, { Document, Schema } from 'mongoose';

export enum MessageType {
  TEXT = 'text',
  IMAGE = 'image',
  FILE = 'file',
}

export enum MessageStatus {
  SENT = 'sent',
  DELIVERED = 'delivered',
  READ = 'read',
}

export interface IMessage extends Document {
  _id: mongoose.Types.ObjectId;
  chatRoomId: mongoose.Types.ObjectId;
  senderId: mongoose.Types.ObjectId;
  content: string;
  type: MessageType;
  status: MessageStatus;
  readBy: {
    userId: mongoose.Types.ObjectId;
    readAt: Date;
  }[];
  edited: boolean;
  editedAt?: Date;
  replyTo?: mongoose.Types.ObjectId;
  metadata?: {
    fileName?: string;
    fileSize?: number;
    mimeType?: string;
    imageWidth?: number;
    imageHeight?: number;
  };
  createdAt: Date;
  updatedAt: Date;
  markAsRead(userId: mongoose.Types.ObjectId): Promise<IMessage>;
  markAsDelivered(): Promise<IMessage>;
  editContent(newContent: string): Promise<IMessage>;
}

export interface IMessageModel extends mongoose.Model<IMessage> {
  getUnreadCount(
    chatRoomId: mongoose.Types.ObjectId,
    userId: mongoose.Types.ObjectId
  ): Promise<number>;
  markRoomMessagesAsRead(
    chatRoomId: mongoose.Types.ObjectId,
    userId: mongoose.Types.ObjectId
  ): Promise<mongoose.UpdateWriteOpResult>;
}

const messageSchema = new Schema<IMessage>(
  {
    chatRoomId: {
      type: Schema.Types.ObjectId,
      ref: 'ChatRoom',
      required: [true, 'Chat room ID is required'],
      index: true,
    },
    senderId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Sender ID is required'],
      index: true,
    },
    content: {
      type: String,
      required: [true, 'Message content is required'],
      maxlength: [2000, 'Message content cannot exceed 2000 characters'],
      trim: true,
    },
    type: {
      type: String,
      enum: Object.values(MessageType),
      default: MessageType.TEXT,
    },
    status: {
      type: String,
      enum: Object.values(MessageStatus),
      default: MessageStatus.SENT,
    },
    readBy: [
      {
        userId: {
          type: Schema.Types.ObjectId,
          ref: 'User',
          required: true,
        },
        readAt: {
          type: Date,
          required: true,
        },
      },
    ],
    edited: {
      type: Boolean,
      default: false,
    },
    editedAt: {
      type: Date,
    },
    replyTo: {
      type: Schema.Types.ObjectId,
      ref: 'Message',
    },
    metadata: {
      fileName: String,
      fileSize: Number,
      mimeType: String,
      imageWidth: Number,
      imageHeight: Number,
    },
  },
  {
    timestamps: true,
  }
);

messageSchema.methods.markAsRead = function (userId: mongoose.Types.ObjectId) {
  const existingRead = this.readBy.find(
    (read: { userId: mongoose.Types.ObjectId; readAt: Date }) =>
      read.userId.equals(userId)
  );

  if (!existingRead) {
    this.readBy.push({
      userId,
      readAt: new Date(),
    } as { userId: mongoose.Types.ObjectId; readAt: Date });
  }

  return this.save();
};

messageSchema.methods.markAsDelivered = function () {
  this.status = MessageStatus.DELIVERED;
  return this.save();
};

messageSchema.methods.editContent = function (newContent: string) {
  this.content = newContent;
  this.edited = true;
  this.editedAt = new Date();
  return this.save();
};

messageSchema.statics.getUnreadCount = function (
  chatRoomId: mongoose.Types.ObjectId,
  userId: mongoose.Types.ObjectId
) {
  return this.countDocuments({
    chatRoomId,
    senderId: { $ne: userId },
    'readBy.userId': { $ne: userId },
  });
};

messageSchema.statics.markRoomMessagesAsRead = function (
  chatRoomId: mongoose.Types.ObjectId,
  userId: mongoose.Types.ObjectId
) {
  return this.updateMany(
    {
      chatRoomId,
      senderId: { $ne: userId },
      'readBy.userId': { $ne: userId },
    },
    {
      $push: {
        readBy: {
          userId,
          readAt: new Date(),
        },
      },
    }
  );
};

messageSchema.index({ chatRoomId: 1, createdAt: -1 });
messageSchema.index({ senderId: 1, createdAt: -1 });
messageSchema.index({ 'readBy.userId': 1 });
messageSchema.index({ status: 1 });
messageSchema.index({ type: 1 });

export const Message = mongoose.model<IMessage, IMessageModel>(
  'Message',
  messageSchema
);
