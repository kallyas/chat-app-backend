import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat_room.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../chat/chat_screen.dart';
import '../chat/create_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<User> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadChatRooms(refresh: true);
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final results = await chatProvider.searchUsers(query);
    
    setState(() {
      _searchResults = results;
    });
  }

  Future<void> _startChat(User user) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if private chat already exists
    final existingRoom = chatProvider.chatRooms.firstWhere(
      (room) => room.type == ChatRoomType.private &&
          room.participants.any((p) => p.id == user.id) &&
          room.participants.any((p) => p.id == authProvider.currentUserId),
      orElse: () => throw Exception('Not found'),
    );

    ChatRoom? chatRoom;
    if (existingRoom.id.isNotEmpty) {
      chatRoom = existingRoom;
    } else {
      chatRoom = await chatProvider.createPrivateChat(user.id);
    }

    if (chatRoom != null && mounted) {
      _clearSearch();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoom: chatRoom!),
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, ChatProvider, ThemeProvider>(
      builder: (context, authProvider, chatProvider, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chats'),
            backgroundColor: themeProvider.surfaceColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _clearSearch();
                    }
                  });
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'new_group':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateChatScreen(),
                        ),
                      );
                      break;
                    case 'refresh':
                      _handleRefresh();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'new_group',
                    child: Row(
                      children: [
                        Icon(Icons.group_add),
                        SizedBox(width: 12),
                        Text('New Group'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 12),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              if (_isSearching)
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: themeProvider.surfaceColor,
                    border: Border(
                      bottom: BorderSide(
                        color: themeProvider.dividerColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: themeProvider.surfaceVariantColor,
                    ),
                    onChanged: _handleSearch,
                  ),
                ),

              // Content
              Expanded(
                child: _isSearching ? _buildSearchResults() : _buildChatList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatList() {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        if (chatProvider.isLoading && chatProvider.chatRooms.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (chatProvider.chatRooms.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            itemCount: chatProvider.chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatProvider.chatRooms[index];
              return _buildChatListItem(chatRoom);
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: themeProvider.secondaryTextColor,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'No users found',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final user = _searchResults[index];
            return _buildUserListItem(user);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                'No chats yet',
                style: TextStyle(
                  color: themeProvider.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Start a conversation by searching for users',
                style: TextStyle(
                  color: themeProvider.secondaryTextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
                icon: const Icon(Icons.search),
                label: const Text('Search Users'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatListItem(ChatRoom chatRoom) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final currentUserId = authProvider.currentUserId ?? '';
        final displayName = chatRoom.getDisplayName(currentUserId);
        final lastMessage = chatRoom.lastMessage;
        final isOnline = chatRoom.isUserOnline(currentUserId);

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: themeProvider.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppConstants.primaryBlue,
                  backgroundImage: chatRoom.getDisplayAvatar(currentUserId).isNotEmpty
                      ? NetworkImage(chatRoom.getDisplayAvatar(currentUserId))
                      : null,
                  child: chatRoom.getDisplayAvatar(currentUserId).isEmpty
                      ? Text(
                          chatRoom.getDisplayInitials(currentUserId),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (chatRoom.type == ChatRoomType.private && isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: themeProvider.onlineColor,
                        border: Border.all(
                          color: themeProvider.surfaceColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: themeProvider.primaryTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastMessage != null)
                  Text(
                    lastMessage.displayContent,
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (chatRoom.type == ChatRoomType.private)
                  Text(
                    chatRoom.getLastSeenText(currentUserId),
                    style: TextStyle(
                      color: isOnline ? themeProvider.onlineColor : themeProvider.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lastMessage != null)
                  Text(
                    Formatters.formatTimeAgo(lastMessage.createdAt),
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                if (chatRoom.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chatRoom.unreadCount > 99 ? '99+' : chatRoom.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chatRoom: chatRoom),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserListItem(User user) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: themeProvider.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppConstants.primaryBlue,
                  backgroundImage: user.profilePic?.isNotEmpty == true
                      ? NetworkImage(user.profilePic!)
                      : null,
                  child: user.profilePic?.isEmpty != false
                      ? Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (user.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: themeProvider.onlineColor,
                        border: Border.all(
                          color: themeProvider.surfaceColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              user.username,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: themeProvider.primaryTextColor,
              ),
            ),
            subtitle: Text(
              user.onlineStatusText,
              style: TextStyle(
                color: user.isOnline ? themeProvider.onlineColor : themeProvider.secondaryTextColor,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(Icons.chat_bubble_outline),
            onTap: () => _startChat(user),
          ),
        );
      },
    );
  }
}