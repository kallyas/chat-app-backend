import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _initialized = false;

  static const _pages = [
    ChatListScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_initialized) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.isAuthenticated) {
      _initialized = true;
      await chatProvider.initialize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final chatProvider = context.read<ChatProvider>();

    if (state == AppLifecycleState.resumed) {
      chatProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        return Scaffold(
          extendBody: true,
          body: Container(
            decoration: BoxDecoration(gradient: themeProvider.shellGradient),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  IndexedStack(index: _currentIndex, children: _pages),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.defaultPadding,
                        0,
                        AppConstants.defaultPadding,
                        AppConstants.defaultPadding,
                      ),
                      child: _FloatingNavBar(
                        currentIndex: _currentIndex,
                        unreadCount: chatProvider.totalUnreadCount,
                        onTap: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final items = [
      (
        icon: Icons.forum_outlined,
        activeIcon: Icons.forum,
        label: 'Inbox',
      ),
      (
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
      (
        icon: Icons.tune_rounded,
        activeIcon: Icons.tune,
        label: 'Settings',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: themeProvider.panelGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: themeProvider.borderColor.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: themeProvider.shadowColor,
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: AppConstants.mediumAnimation,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? themeProvider.accentColor.withOpacity(
                              themeProvider.isDarkMode ? 0.2 : 0.14,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive
                                  ? themeProvider.accentColor
                                  : themeProvider.secondaryTextColor,
                            ),
                            if (index == 0 && unreadCount > 0)
                              Positioned(
                                right: -9,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: themeProvider.unreadCountColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: TextStyle(
                                      color: themeProvider.unreadCountTextColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        AnimatedSize(
                          duration: AppConstants.mediumAnimation,
                          curve: Curves.easeOutCubic,
                          child: isActive
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: themeProvider.primaryTextColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
