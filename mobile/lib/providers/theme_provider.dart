import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  // Light theme
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
      );

  // Dark theme
  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade600),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade700,
          thickness: 1,
        ),
      );

  // Custom colors for the app
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  
  // Message bubble colors
  Color get sentMessageColor => isDarkMode 
      ? const Color(0xFF2196F3)
      : const Color(0xFF2196F3);
      
  Color get receivedMessageColor => isDarkMode 
      ? const Color(0xFF424242)
      : const Color(0xFFE0E0E0);
      
  Color get sentMessageTextColor => Colors.white;
  
  Color get receivedMessageTextColor => isDarkMode 
      ? Colors.white
      : Colors.black87;

  // Online status colors
  Color get onlineColor => const Color(0xFF4CAF50);
  Color get offlineColor => Colors.grey;
  Color get awayColor => const Color(0xFFFF9800);

  // Typing indicator color
  Color get typingIndicatorColor => isDarkMode 
      ? Colors.blue.shade300
      : Colors.blue.shade600;

  // Unread count colors
  Color get unreadCountColor => const Color(0xFFF44336);
  Color get unreadCountTextColor => Colors.white;

  // App bar gradient
  Gradient get appBarGradient => LinearGradient(
        colors: [
          primaryBlue,
          primaryDark,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Chat background
  Color get chatBackgroundColor => isDarkMode 
      ? const Color(0xFF121212)
      : const Color(0xFFF5F5F5);

  // Input field background
  Color get inputBackgroundColor => isDarkMode 
      ? const Color(0xFF2C2C2C)
      : Colors.white;

  // Divider color
  Color get dividerColor => isDarkMode 
      ? Colors.grey.shade700
      : Colors.grey.shade300;

  // Surface colors
  Color get surfaceColor => isDarkMode 
      ? const Color(0xFF1E1E1E)
      : Colors.white;

  Color get surfaceVariantColor => isDarkMode 
      ? const Color(0xFF2C2C2C)
      : const Color(0xFFF8F8F8);

  // Text colors
  Color get primaryTextColor => isDarkMode 
      ? Colors.white
      : Colors.black87;

  Color get secondaryTextColor => isDarkMode 
      ? Colors.grey.shade400
      : Colors.grey.shade600;

  Color get hintTextColor => isDarkMode 
      ? Colors.grey.shade500
      : Colors.grey.shade500;

  // Border colors
  Color get borderColor => isDarkMode 
      ? Colors.grey.shade600
      : Colors.grey.shade300;

  // Shadow colors
  Color get shadowColor => isDarkMode 
      ? Colors.black26
      : Colors.black12;

  // Shimmer colors for loading states
  Color get shimmerBaseColor => isDarkMode 
      ? Colors.grey.shade800
      : Colors.grey.shade300;

  Color get shimmerHighlightColor => isDarkMode 
      ? Colors.grey.shade700
      : Colors.grey.shade100;

  // File type colors
  Color getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFD32F2F);
      case 'doc':
      case 'docx':
        return const Color(0xFF1976D2);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF388E3C);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFD84315);
      case 'zip':
      case 'rar':
        return const Color(0xFF7B1FA2);
      case 'txt':
        return const Color(0xFF5D4037);
      default:
        return Colors.grey;
    }
  }
}