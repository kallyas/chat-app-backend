import 'user.dart';

enum MessageType { text, image, file }
enum MessageStatus { sent, delivered, read }

class MessageMetadata {
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? imageWidth;
  final int? imageHeight;

  const MessageMetadata({
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.imageWidth,
    this.imageHeight,
  });

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    return MessageMetadata(
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      imageWidth: json['imageWidth'],
      imageHeight: json['imageHeight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
    };
  }
}

class ReadReceipt {
  final String userId;
  final DateTime readAt;

  const ReadReceipt({
    required this.userId,
    required this.readAt,
  });

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      userId: json['userId'],
      readAt: DateTime.parse(json['readAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'readAt': readAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final User? sender;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final List<ReadReceipt> readBy;
  final bool edited;
  final DateTime? editedAt;
  final String? replyToId;
  final Message? replyTo;
  final MessageMetadata? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    this.sender,
    required this.content,
    required this.type,
    required this.status,
    required this.readBy,
    required this.edited,
    this.editedAt,
    this.replyToId,
    this.replyTo,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      chatRoomId: json['chatRoomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['sender']?['_id']?.toString() ?? json['sender']?['id']?.toString() ?? '',
      sender: json['sender'] is Map<String, dynamic> 
          ? User.fromJson(json['sender'])
          : null,
      content: json['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? json['messageType']),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((r) => ReadReceipt.fromJson(r))
          .toList() ?? [],
      edited: json['edited'] ?? false,
      editedAt: json['editedAt'] != null 
          ? DateTime.tryParse(json['editedAt'].toString())
          : null,
      replyToId: json['replyTo'] is String 
          ? json['replyTo'] 
          : json['replyTo']?['_id']?.toString(),
      replyTo: json['replyTo'] is Map<String, dynamic>
          ? Message.fromJson(json['replyTo'])
          : null,
      metadata: json['metadata'] != null 
          ? MessageMetadata.fromJson(json['metadata'])
          : null,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is String) {
      return DateTime.tryParse(dateValue);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'sender': sender?.toJson(),
      'content': content,
      'type': type.name,
      'status': status.name,
      'readBy': readBy.map((r) => r.toJson()).toList(),
      'edited': edited,
      'editedAt': editedAt?.toIso8601String(),
      'replyTo': replyToId,
      'metadata': metadata?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    User? sender,
    String? content,
    MessageType? type,
    MessageStatus? status,
    List<ReadReceipt>? readBy,
    bool? edited,
    DateTime? editedAt,
    String? replyToId,
    Message? replyTo,
    MessageMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, content: $content, type: $type)';
  }

  // Helper methods
  bool isReadBy(String userId) {
    return readBy.any((r) => r.userId == userId);
  }

  String get senderName => sender?.username ?? 'Unknown';

  String get displayContent {
    switch (type) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return metadata?.fileName ?? 'Image';
      case MessageType.file:
        return metadata?.fileName ?? 'File';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  String get formattedTime {
    final hour = createdAt.hour;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get formattedDate {
    final now = DateTime.now();
    final messageDate = createdAt;
    
    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      return 'Today';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (messageDate.year == yesterday.year &&
        messageDate.month == yesterday.month &&
        messageDate.day == yesterday.day) {
      return 'Yesterday';
    }
    
    return '${messageDate.day}/${messageDate.month}/${messageDate.year}';
  }

  bool get canEdit {
    // Messages can be edited within 15 minutes of sending
    final editWindow = Duration(minutes: 15);
    return DateTime.now().difference(createdAt) < editWindow && type == MessageType.text;
  }

  bool get canDelete {
    // Messages can be deleted within 1 hour of sending
    final deleteWindow = Duration(hours: 1);
    return DateTime.now().difference(createdAt) < deleteWindow;
  }

  String? get fileSizeFormatted {
    if (metadata?.fileSize == null) return null;
    
    final bytes = metadata!.fileSize!;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}