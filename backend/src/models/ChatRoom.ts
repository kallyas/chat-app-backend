import mongoose, { Document, Schema } from 'mongoose';

export enum ChatRoomType {
  PRIVATE = 'private',
  GROUP = 'group',
}

export interface IChatRoom extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  type: ChatRoomType;
  participants: mongoose.Types.ObjectId[];
  createdBy: mongoose.Types.ObjectId;
  description?: string;
  avatar?: string;
  isActive: boolean;
  lastMessage?: {
    content: string;
    sender: mongoose.Types.ObjectId;
    timestamp: Date;
    messageType: 'text' | 'image' | 'file';
  };
  createdAt: Date;
  updatedAt: Date;
  addParticipant(userId: mongoose.Types.ObjectId): Promise<IChatRoom>;
  removeParticipant(userId: mongoose.Types.ObjectId): Promise<IChatRoom>;
  updateLastMessage(content: string, senderId: mongoose.Types.ObjectId, messageType?: 'text' | 'image' | 'file'): Promise<IChatRoom>;
}

const chatRoomSchema = new Schema<IChatRoom>(
  {
    name: {
      type: String,
      required: function(this: IChatRoom) {
        return this.type === ChatRoomType.GROUP;
      },
      trim: true,
      maxlength: [50, 'Room name cannot exceed 50 characters'],
    },
    type: {
      type: String,
      enum: Object.values(ChatRoomType),
      required: [true, 'Chat room type is required'],
    },
    participants: [
      {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Creator is required'],
    },
    description: {
      type: String,
      maxlength: [200, 'Description cannot exceed 200 characters'],
      trim: true,
    },
    avatar: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastMessage: {
      content: {
        type: String,
        required: false,
      },
      sender: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: false,
      },
      timestamp: {
        type: Date,
        required: false,
      },
      messageType: {
        type: String,
        enum: ['text', 'image', 'file'],
        default: 'text',
      },
    },
  },
  {
    timestamps: true,
  }
);

chatRoomSchema.pre('save', function (next) {
  if (this.type === ChatRoomType.PRIVATE) {
    if (this.participants.length !== 2) {
      return next(new Error('Private chat room must have exactly 2 participants'));
    }
    // Private chats don't need a name - leave it undefined
  }

  if (this.type === ChatRoomType.GROUP && this.participants.length < 3) {
    return next(new Error('Group chat room must have at least 3 participants'));
  }

  next();
});

chatRoomSchema.methods.addParticipant = function (userId: mongoose.Types.ObjectId) {
  if (this.type === ChatRoomType.PRIVATE) {
    throw new Error('Cannot add participants to private chat');
  }
  
  if (!this.participants.some((id: mongoose.Types.ObjectId) => id.equals(userId))) {
    this.participants.push(userId);
  }
  
  return this.save();
};

chatRoomSchema.methods.removeParticipant = function (userId: mongoose.Types.ObjectId) {
  this.participants = this.participants.filter(
    (participantId: mongoose.Types.ObjectId) => !participantId.equals(userId)
  ) as mongoose.Types.ObjectId[];
  
  if (this.participants.length === 0) {
    this.isActive = false;
  }
  
  return this.save();
};

chatRoomSchema.methods.updateLastMessage = function (
  content: string,
  senderId: mongoose.Types.ObjectId,
  messageType: 'text' | 'image' | 'file' = 'text'
) {
  this.lastMessage = {
    content,
    sender: senderId,
    timestamp: new Date(),
    messageType,
  };
  
  return this.save();
};

chatRoomSchema.index({ participants: 1 });
chatRoomSchema.index({ type: 1 });
chatRoomSchema.index({ isActive: 1 });
chatRoomSchema.index({ createdBy: 1 });
chatRoomSchema.index({ 'lastMessage.timestamp': -1 });

chatRoomSchema.index(
  { participants: 1, type: 1 },
  { 
    unique: true,
    partialFilterExpression: { type: ChatRoomType.PRIVATE }
  }
);

export const ChatRoom = mongoose.model<IChatRoom>('ChatRoom', chatRoomSchema);