import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_room.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
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
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearchLoading = false;
  List<User> _searchResults = [];
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<ChatProvider>().loadChatRooms(refresh: true);
  }

  void _handleSearch(String query) {
    _searchDebounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _isSearchLoading = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
    });

    _searchDebounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => _performSearch(query.trim()),
    );
  }

  Future<void> _performSearch(String query) async {
    final results = await context.read<ChatProvider>().searchUsers(query);

    if (!mounted) {
      return;
    }

    setState(() {
      _searchResults = results;
      _isSearchLoading = false;
    });
  }

  Future<void> _startChat(User user) async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUserId;

    if (currentUserId == null) {
      return;
    }

    ChatRoom? existingRoom;
    for (final room in chatProvider.chatRooms) {
      final isPrivate = room.type == ChatRoomType.private;
      final hasTarget = room.participants.any((p) => p.id == user.id);
      final hasCurrent = room.participants.any((p) => p.id == currentUserId);
      if (isPrivate && hasTarget && hasCurrent) {
        existingRoom = room;
        break;
      }
    }

    final room = existingRoom ?? await chatProvider.createPrivateChat(user.id);
    if (!mounted || room == null) {
      return;
    }

    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearchLoading = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(chatRoom: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = context.select<AuthProvider, String>(
      (provider) => provider.currentUserId ?? '',
    );
    final chatRooms = context.select<ChatProvider, List<ChatRoom>>(
      (provider) => provider.chatRooms,
    );
    final totalUnreadCount = context.select<ChatProvider, int>(
      (provider) => provider.totalUnreadCount,
    );
    final showLoading = context.select<ChatProvider, bool>(
      (provider) =>
          (provider.isLoading || provider.isLoadingChatRooms) &&
          provider.chatRooms.isEmpty,
    );
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InboxHeader(
              unreadCount: totalUnreadCount,
              activeRooms: chatRooms.length,
              onCreateGroup: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateChatScreen()),
                );
              },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Search people or jump into an existing conversation',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _isSearchLoading = false;
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: themeProvider.panelGradient,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: themeProvider.borderColor.withOpacity(0.68),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: showLoading
                      ? const Center(child: CircularProgressIndicator())
                      : isSearching
                          ? _SearchResults(
                              isLoading: _isSearchLoading,
                              results: _searchResults,
                              onUserTap: _startChat,
                            )
                          : chatRooms.isEmpty
                              ? _EmptyInbox(
                                  onSearchTap: () {
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : RefreshIndicator(
                                  onRefresh: _handleRefresh,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: chatRooms.length,
                                    itemBuilder: (context, index) {
                                      final room = chatRooms[index];
                                      return _ChatRoomTile(
                                        chatRoom: room,
                                        currentUserId: currentUserId,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ChatScreen(chatRoom: room),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                ),
              ),
            ),
            if (!isSearching && chatRooms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Pull to refresh. Rooms with unread activity stay pinned to the top.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({
    required this.unreadCount,
    required this.activeRooms,
    required this.onCreateGroup,
  });

  final int unreadCount;
  final int activeRooms;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: themeProvider.appBarGradient,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inbox',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    onPressed: onCreateGroup,
                    icon: const Icon(Icons.add_comment_rounded,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Keep momentum with active rooms, visible unread load, and faster jump-back into live chats.',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.82),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _HeaderMetric(
                  label: 'Unread',
                  value: unreadCount > 99 ? '99+' : '$unreadCount',
                ),
                const SizedBox(width: 12),
                _HeaderMetric(
                  label: 'Rooms',
                  value: '$activeRooms',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.isLoading,
    required this.results,
    required this.onUserTap,
  });

  final bool isLoading;
  final List<User> results;
  final ValueChanged<User> onUserTap;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              size: 54,
              color: themeProvider.secondaryTextColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No matching users yet',
              style: TextStyle(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = results[index];
        return _UserResultTile(user: user, onTap: () => onUserTap(user));
      },
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: themeProvider.subtleAccent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.mark_chat_unread_outlined,
                color: themeProvider.accentColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text('No conversations yet', style: textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Search for teammates or create a group to start a cleaner, more focused inbox.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: themeProvider.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onSearchTap,
              child: const Text('Search people'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
  });

  final ChatRoom chatRoom;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final displayName = chatRoom.getDisplayName(currentUserId);
    final avatar = chatRoom.getDisplayAvatar(currentUserId);
    final isOnline = chatRoom.isUserOnline(currentUserId);
    final lastMessage = chatRoom.lastMessage;
    final preview = chatRoom.getLastMessagePreview() ??
        'No messages yet. Start the thread.';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: themeProvider.accentColor.withOpacity(0.2),
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                          chatRoom.getDisplayInitials(currentUserId),
                          style: TextStyle(
                            color: themeProvider.primaryTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                if (chatRoom.type == ChatRoomType.private)
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? themeProvider.onlineColor
                            : themeProvider.offlineColor,
                        border: Border.all(
                          color: themeProvider.surfaceColor,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: themeProvider.primaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (lastMessage != null)
                        Text(
                          Formatters.formatTimeAgo(lastMessage.createdAt),
                          style: TextStyle(
                            color: themeProvider.secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        chatRoom.getLastSeenText(currentUserId),
                        style: TextStyle(
                          color: isOnline
                              ? themeProvider.onlineColor
                              : themeProvider.secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (chatRoom.unreadCount > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.unreadCountColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            chatRoom.unreadCount > 99
                                ? '99+'
                                : '${chatRoom.unreadCount}',
                            style: TextStyle(
                              color: themeProvider.unreadCountTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  const _UserResultTile({required this.user, required this.onTap});

  final User user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: themeProvider.surfaceVariantColor.withOpacity(0.55),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: themeProvider.accentColor.withOpacity(0.18),
              backgroundImage: user.profilePic?.isNotEmpty == true
                  ? NetworkImage(user.profilePic!)
                  : null,
              child: user.profilePic?.isEmpty != false
                  ? Text(
                      user.initials,
                      style: TextStyle(
                        color: themeProvider.primaryTextColor,
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
                    user.username,
                    style: TextStyle(
                      color: themeProvider.primaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.onlineStatusText,
                    style: TextStyle(
                      color: user.isOnline
                          ? themeProvider.onlineColor
                          : themeProvider.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                color: themeProvider.secondaryTextColor),
          ],
        ),
      ),
    );
  }
}
