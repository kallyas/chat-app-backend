import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat_room.dart';
import '../../models/message.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({
    super.key,
    required this.chatRoom,
  });

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
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.setCurrentChatRoom(widget.chatRoom.id);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Clear the input field immediately
    _messageController.clear();
    
    // Stop typing indicator
    if (_isTyping) {
      chatProvider.stopTyping(widget.chatRoom.id);
      setState(() {
        _isTyping = false;
      });
    }

    // Send the message
    await chatProvider.sendMessage(
      chatRoomId: widget.chatRoom.id,
      content: message,
    );

    // Scroll to bottom
    _scrollToBottom();
  }

  void _onMessageChanged(String text) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      chatProvider.startTyping(widget.chatRoom.id);
    } else if (text.isEmpty && _isTyping) {
      setState(() {
        _isTyping = false;
      });
      chatProvider.stopTyping(widget.chatRoom.id);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppConstants.shortAnimation,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, ChatProvider, ThemeProvider>(
      builder: (context, authProvider, chatProvider, themeProvider, child) {
        final currentUserId = authProvider.currentUserId ?? '';
        final messages = chatProvider.getMessages(widget.chatRoom.id);
        final typingUsers = chatProvider.getTypingUsers(widget.chatRoom.id);

        return Scaffold(
          appBar: _buildAppBar(currentUserId, themeProvider),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: Container(
                  color: themeProvider.chatBackgroundColor,
                  child: messages.isEmpty
                      ? _buildEmptyState(themeProvider)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == currentUserId;
                            final showAvatar = !isMe && (index == messages.length - 1 || 
                                messages[index + 1].senderId != message.senderId);
                            
                            return _buildMessageBubble(
                              message,
                              isMe,
                              showAvatar,
                              themeProvider,
                            );
                          },
                        ),
                ),
              ),

              // Typing indicator
              if (typingUsers.isNotEmpty)
                _buildTypingIndicator(typingUsers, themeProvider),

              // Message input
              _buildMessageInput(themeProvider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String currentUserId, ThemeProvider themeProvider) {
    final displayName = widget.chatRoom.getDisplayName(currentUserId);
    final isOnline = widget.chatRoom.isUserOnline(currentUserId);
    final lastSeenText = widget.chatRoom.getLastSeenText(currentUserId);

    return AppBar(
      backgroundColor: themeProvider.surfaceColor,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          chatProvider.setCurrentChatRoom(null);
          Navigator.of(context).pop();
        },
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppConstants.primaryBlue,
            backgroundImage: widget.chatRoom.getDisplayAvatar(currentUserId).isNotEmpty
                ? NetworkImage(widget.chatRoom.getDisplayAvatar(currentUserId))
                : null,
            child: widget.chatRoom.getDisplayAvatar(currentUserId).isEmpty
                ? Text(
                    widget.chatRoom.getDisplayInitials(currentUserId),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.chatRoom.type == ChatRoomType.private)
                  Text(
                    lastSeenText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? themeProvider.onlineColor : themeProvider.secondaryTextColor,
                    ),
                  )
                else
                  Text(
                    lastSeenText,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () {
            // TODO: Implement video call
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () {
            // TODO: Implement voice call
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'info':
                // TODO: Navigate to chat info
                break;
              case 'mute':
                // TODO: Implement mute
                break;
              case 'clear':
                // TODO: Implement clear chat
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Text('Chat Info'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off_outlined),
                  SizedBox(width: 12),
                  Text('Mute'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 12),
                  Text('Clear Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: themeProvider.secondaryTextColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No messages yet',
            style: TextStyle(
              color: themeProvider.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isMe,
    bool showAvatar,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppConstants.primaryBlue,
              backgroundImage: message.sender?.profilePic?.isNotEmpty == true
                  ? NetworkImage(message.sender!.profilePic!)
                  : null,
              child: message.sender?.profilePic?.isEmpty != false
                  ? Text(
                      message.sender?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            )
          else if (!isMe)
            const SizedBox(width: 32),
          
          const SizedBox(width: 8),
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isMe 
                    ? themeProvider.sentMessageColor 
                    : themeProvider.receivedMessageColor,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && widget.chatRoom.type == ChatRoomType.group)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        color: AppConstants.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe 
                          ? themeProvider.sentMessageTextColor 
                          : themeProvider.receivedMessageTextColor,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      color: (isMe 
                          ? themeProvider.sentMessageTextColor 
                          : themeProvider.receivedMessageTextColor).withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(List<String> typingUsers, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          const SizedBox(width: 40), // Space for avatar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeProvider.receivedMessageColor,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.formatTypingIndicator(typingUsers),
                  style: TextStyle(
                    color: themeProvider.receivedMessageTextColor,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.typingIndicatorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        border: Border(
          top: BorderSide(
            color: themeProvider.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement file attachment
            },
          ),
          
          Expanded(
            child: TextField(
              controller: _messageController,
              textInputAction: TextInputAction.send,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onChanged: _onMessageChanged,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: themeProvider.inputBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppConstants.smallPadding),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: AppConstants.primaryBlue,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}