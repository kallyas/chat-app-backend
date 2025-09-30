import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  
  bool _isGroupChat = false;
  List<User> _searchResults = [];
  List<User> _selectedUsers = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
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
    
    // Filter out current user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final filteredResults = results.where(
      (user) => user.id != authProvider.currentUserId,
    ).toList();
    
    setState(() {
      _searchResults = filteredResults;
    });
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
        if (!_isGroupChat && _selectedUsers.length == 1) {
          // For direct chat, automatically proceed
          _createChat();
        }
      }
    });
  }

  Future<void> _createChat() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (_isGroupChat) {
      // Validate group name
      final groupNameError = Validators.validateChatRoomName(_groupNameController.text);
      if (groupNameError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupNameError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create group chat
      final chatRoom = await chatProvider.createGroupChat(
        name: _groupNameController.text.trim(),
        participants: _selectedUsers.map((u) => u.id).toList(),
        description: _groupDescriptionController.text.trim().isNotEmpty 
            ? _groupDescriptionController.text.trim() 
            : null,
      );

      if (chatRoom != null && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group chat created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Create private chat
      final user = _selectedUsers.first;
      final chatRoom = await chatProvider.createPrivateChat(user.id);

      if (chatRoom != null && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isGroupChat ? 'New Group' : 'New Chat'),
            backgroundColor: themeProvider.surfaceColor,
            elevation: 0,
            actions: [
              if (_selectedUsers.isNotEmpty)
                TextButton(
                  onPressed: _createChat,
                  child: Text(
                    _isGroupChat ? 'Create' : 'Chat',
                    style: const TextStyle(
                      color: AppConstants.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Chat type selector
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
                child: Row(
                  children: [
                    Expanded(
                      child: _buildChatTypeOption(
                        'Direct Chat',
                        'Chat with one person',
                        Icons.person,
                        !_isGroupChat,
                        () => setState(() => _isGroupChat = false),
                        themeProvider,
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: _buildChatTypeOption(
                        'Group Chat',
                        'Chat with multiple people',
                        Icons.group,
                        _isGroupChat,
                        () => setState(() => _isGroupChat = true),
                        themeProvider,
                      ),
                    ),
                  ],
                ),
              ),

              // Group details (if group chat)
              if (_isGroupChat) ...[
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
                  child: Column(
                    children: [
                      TextField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                          hintText: 'Enter group name',
                          prefixIcon: Icon(Icons.group),
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      TextField(
                        controller: _groupDescriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Enter group description',
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Selected users
              if (_selectedUsers.isNotEmpty)
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: themeProvider.surfaceVariantColor,
                    border: Border(
                      bottom: BorderSide(
                        color: themeProvider.dividerColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected (${_selectedUsers.length})',
                        style: TextStyle(
                          color: themeProvider.secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _selectedUsers[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildSelectedUserChip(user, themeProvider),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Search bar
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
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                            },
                          )
                        : null,
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

              // Search results
              Expanded(
                child: _buildSearchResults(themeProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatTypeOption(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ThemeProvider themeProvider,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConstants.primaryBlue.withOpacity(0.1)
              : themeProvider.surfaceVariantColor,
          border: Border.all(
            color: isSelected 
                ? AppConstants.primaryBlue 
                : themeProvider.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppConstants.primaryBlue 
                  : themeProvider.secondaryTextColor,
              size: 32,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: TextStyle(
                color: isSelected 
                    ? AppConstants.primaryBlue 
                    : themeProvider.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUserChip(User user, ThemeProvider themeProvider) {
    return Column(
      children: [
        Stack(
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
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: () => _toggleUserSelection(user),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppConstants.errorRed,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeProvider.surfaceColor,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user.username,
          style: TextStyle(
            color: themeProvider.primaryTextColor,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSearchResults(ThemeProvider themeProvider) {
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

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: themeProvider.secondaryTextColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Search for users to start chatting',
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
        final isSelected = _selectedUsers.contains(user);

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
            leading: CircleAvatar(
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
            title: Text(
              user.username,
              style: TextStyle(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              user.onlineStatusText,
              style: TextStyle(
                color: user.isOnline 
                    ? themeProvider.onlineColor 
                    : themeProvider.secondaryTextColor,
              ),
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: AppConstants.primaryBlue,
                  )
                : const Icon(Icons.add_circle_outline),
            onTap: () => _toggleUserSelection(user),
          ),
        );
      },
    );
  }
}