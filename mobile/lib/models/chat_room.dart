import 'user.dart';
import 'message.dart';

enum ChatRoomType { private, group }

class ChatRoom {
  final String id;
  final String? name;
  final ChatRoomType type;
  final List<User> participants;
  final String? description;
  final String? avatar;
  final String createdBy;
  final bool isActive;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoom({
    required this.id,
    this.name,
    required this.type,
    required this.participants,
    this.description,
    this.avatar,
    required this.createdBy,
    required this.isActive,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      type: ChatRoomType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatRoomType.private,
      ),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => User.fromJson(p is Map<String, dynamic> ? p : {'_id': p.toString(), 'username': '', 'email': '', 'isOnline': false, 'createdAt': DateTime.now().toIso8601String(), 'updatedAt': DateTime.now().toIso8601String()}))
          .toList() ?? [],
      description: json['description'],
      avatar: json['avatar'],
      createdBy: json['createdBy'] ?? json['creator'] ?? '',
      isActive: json['isActive'] ?? true,
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type.name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'description': description,
      'avatar': avatar,
      'createdBy': createdBy,
      'isActive': isActive,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    ChatRoomType? type,
    List<User>? participants,
    String? description,
    String? avatar,
    String? createdBy,
    bool? isActive,
    Message? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatRoom(id: $id, name: $name, type: $type, participants: ${participants.length})';
  }

  // Helper methods
  String getDisplayName(String currentUserId) {
    if (type == ChatRoomType.group) {
      return name ?? 'Group Chat';
    }
    
    // For private chats, return the other participant's name
    final otherParticipant = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.username;
  }

  String getDisplayAvatar(String currentUserId) {
    if (type == ChatRoomType.group) {
      return avatar ?? '';
    }
    
    // For private chats, return the other participant's avatar
    final otherParticipant = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.profilePic ?? '';
  }

  String getDisplayInitials(String currentUserId) {
    if (type == ChatRoomType.group) {
      final displayName = name ?? 'Group';
      final words = displayName.split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else {
        return displayName.length >= 2 
            ? displayName.substring(0, 2).toUpperCase()
            : displayName.toUpperCase();
      }
    }
    
    // For private chats, return the other participant's initials
    final otherParticipant = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.initials;
  }

  bool isUserOnline(String currentUserId) {
    if (type == ChatRoomType.group) {
      return participants.any((p) => p.id != currentUserId && p.isOnline);
    }
    
    // For private chats, check if the other participant is online
    final otherParticipant = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.isOnline;
  }

  String getLastSeenText(String currentUserId) {
    if (type == ChatRoomType.group) {
      final onlineCount = participants.where((p) => p.id != currentUserId && p.isOnline).length;
      if (onlineCount > 0) {
        return '$onlineCount online';
      }
      return '${participants.length - 1} members';
    }
    
    // For private chats, return the other participant's online status
    final otherParticipant = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.onlineStatusText;
  }

  String? getLastMessagePreview() {
    if (lastMessage == null) return null;
    
    final msg = lastMessage!;
    switch (msg.type) {
      case MessageType.text:
        return msg.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      default:
        return msg.content;
    }
  }
}