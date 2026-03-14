import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_room.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/formatters.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatRoom,
  });

  final ChatRoom chatRoom;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ChatProvider>().setCurrentChatRoom(widget.chatRoom.id);
      _jumpToBottom();
    });
  }

  @override
  void dispose() {
    _stopTypingIfNeeded();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    _messageController.clear();
    _stopTypingIfNeeded();

    await chatProvider.sendMessage(
      chatRoomId: widget.chatRoom.id,
      content: message,
    );

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  void _onMessageChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    final chatProvider = context.read<ChatProvider>();

    if (hasText && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      chatProvider.startTyping(widget.chatRoom.id);
      return;
    }

    if (!hasText && _isTyping) {
      _stopTypingIfNeeded();
    }
  }

  void _stopTypingIfNeeded() {
    if (!_isTyping) {
      return;
    }

    _isTyping = false;
    if (mounted) {
      context.read<ChatProvider>().stopTyping(widget.chatRoom.id);
    }
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.jumpTo(
      _scrollController.position.maxScrollExtent.clamp(0, double.infinity),
    );
  }

  void _closeChat() {
    context.read<ChatProvider>().setCurrentChatRoom(null);
    Navigator.of(context).pop();
  }

  Future<void> _handleMessageActions(Message message, bool isMe) async {
    if (!isMe || message.isDeleted) {
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete message'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (action != 'delete' || !mounted) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete message'),
            content: const Text(
              'This will remove the selected message from the conversation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    final success =
        await context.read<ChatProvider>().deleteMessage(message.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Message deleted' : 'Failed to delete message',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentUserId = context.select<AuthProvider, String>(
      (provider) => provider.currentUserId ?? '',
    );
    final messages = context.select<ChatProvider, List<Message>>(
      (provider) => provider.getMessages(widget.chatRoom.id),
    );
    final typingUsers = context.select<ChatProvider, List<String>>(
      (provider) => provider.getTypingUsers(widget.chatRoom.id),
    );

    final textTheme = Theme.of(context).textTheme;
    final displayName = widget.chatRoom.getDisplayName(currentUserId);
    final isOnline = widget.chatRoom.isUserOnline(currentUserId);
    final presenceLabel = widget.chatRoom.getLastSeenText(currentUserId);

    return Scaffold(
      backgroundColor: themeProvider.chatBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: themeProvider.shellGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ThreadHeader(
                chatRoom: widget.chatRoom,
                currentUserId: currentUserId,
                displayName: displayName,
                isOnline: isOnline,
                presenceLabel: presenceLabel,
                onBack: _closeChat,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  decoration: BoxDecoration(
                    gradient: themeProvider.panelGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: themeProvider.borderColor.withOpacity(0.7),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: messages.isEmpty
                            ? _EmptyThread(displayName: displayName)
                            : ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  16,
                                  24,
                                ),
                                itemCount: messages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe =
                                      message.senderId == currentUserId;
                                  final showAvatar = !isMe &&
                                      (index == messages.length - 1 ||
                                          messages[index + 1].senderId !=
                                              message.senderId);

                                  return _MessageBubble(
                                    message: message,
                                    chatRoom: widget.chatRoom,
                                    isMe: isMe,
                                    showAvatar: showAvatar,
                                    currentUserId: currentUserId,
                                    onLongPress: () =>
                                        _handleMessageActions(message, isMe),
                                  );
                                },
                              ),
                      ),
                      if (typingUsers.isNotEmpty)
                        _TypingBanner(typingUsers: typingUsers),
                      _Composer(
                        controller: _messageController,
                        onChanged: _onMessageChanged,
                        onSend: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: Text(
                  'Messages are delivered live and the thread remains anchored while you move between tabs.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.chatRoom,
    required this.currentUserId,
    required this.displayName,
    required this.isOnline,
    required this.presenceLabel,
    required this.onBack,
  });

  final ChatRoom chatRoom;
  final String currentUserId;
  final String displayName;
  final bool isOnline;
  final String presenceLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final avatar = chatRoom.getDisplayAvatar(currentUserId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: themeProvider.appBarGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: themeProvider.shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.16),
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Text(
                        chatRoom.getDisplayInitials(currentUserId),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? themeProvider.onlineColor
                                : Colors.white.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            presenceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_horiz_rounded, color: Colors.white),
                  onSelected: (_) {},
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'info',
                      child: Text('Conversation details'),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute',
                      child: Text('Mute notifications'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: themeProvider.heroGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.mark_chat_read_outlined,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text('Start the thread', style: textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Send the first message to $displayName and establish the context for this conversation.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: themeProvider.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.chatRoom,
    required this.isMe,
    required this.showAvatar,
    required this.currentUserId,
    required this.onLongPress,
  });

  final Message message;
  final ChatRoom chatRoom;
  final bool isMe;
  final bool showAvatar;
  final String currentUserId;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: showAvatar
                ? CircleAvatar(
                    radius: 15,
                    backgroundColor: themeProvider.subtleAccent,
                    backgroundImage:
                        message.sender?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(message.sender!.avatarUrl)
                            : null,
                    child: message.sender?.avatarUrl.isNotEmpty == true
                        ? null
                        : Text(
                            message.sender?.initials ?? '?',
                            style: TextStyle(
                              color: themeProvider.primaryTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  )
                : const SizedBox(width: 30),
          ),
        Flexible(
          child: GestureDetector(
            onLongPress: onLongPress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isMe
                    ? themeProvider.sentMessageColor
                    : themeProvider.receivedMessageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 8),
                  bottomRight: Radius.circular(isMe ? 8 : 22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.shadowColor,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe && chatRoom.type == ChatRoomType.group)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            color: themeProvider.typingIndicatorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      message.displayContent,
                      style: TextStyle(
                        color: message.isDeleted
                            ? themeProvider.secondaryTextColor
                            : isMe
                                ? themeProvider.sentMessageTextColor
                                : themeProvider.receivedMessageTextColor,
                        fontSize: 15,
                        height: 1.35,
                        fontStyle: message.isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.formattedTime,
                          style: TextStyle(
                            color: (isMe
                                    ? themeProvider.sentMessageTextColor
                                    : themeProvider.receivedMessageTextColor)
                                .withOpacity(0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 8),
                          Icon(
                            message.isReadBy(currentUserId)
                                ? Icons.done_all_rounded
                                : Icons.check_rounded,
                            size: 15,
                            color: (isMe
                                    ? themeProvider.sentMessageTextColor
                                    : themeProvider.receivedMessageTextColor)
                                .withOpacity(0.72),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isMe) const SizedBox(width: 8),
      ],
    );
  }
}

class _TypingBanner extends StatelessWidget {
  const _TypingBanner({required this.typingUsers});

  final List<String> typingUsers;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: themeProvider.surfaceVariantColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.typingIndicatorColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  Formatters.formatTypingIndicator(typingUsers),
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(26),
          border:
              Border.all(color: themeProvider.borderColor.withOpacity(0.82)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: themeProvider.secondaryTextColor,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Write a message with context and next steps',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  gradient: themeProvider.heroGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.arrow_upward_rounded,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
