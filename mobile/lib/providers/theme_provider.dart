import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  ThemeData get lightTheme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF174D4C),
      onPrimary: Color(0xFFFFFCF7),
      secondary: Color(0xFFE9724C),
      onSecondary: Color(0xFFFFFCF7),
      error: Color(0xFFBC3C2F),
      onError: Color(0xFFFFFCF7),
      surface: Color(0xFFFFFCF7),
      onSurface: Color(0xFF13232E),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4EFE6),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF13232E),
          letterSpacing: -0.3,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: Color(0xFF13232E),
          letterSpacing: -1.2,
          height: 1.05,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF13232E),
          letterSpacing: -0.8,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF13232E),
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF13232E),
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.45,
          color: Color(0xFF324250),
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Color(0xFF425565),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFCF7),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: Color(0xFFCFD5CF)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3EEE4),
        hintStyle: const TextStyle(color: Color(0xFF7A837F)),
        labelStyle: const TextStyle(color: Color(0xFF5F6D77)),
        prefixIconColor: const Color(0xFF5F6D77),
        suffixIconColor: const Color(0xFF5F6D77),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF174D4C), width: 1.4),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE3DDD3),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF13232E),
        contentTextStyle: const TextStyle(color: Color(0xFFFFFCF7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: scheme.secondary,
        unselectedItemColor: const Color(0xFF7A837F),
      ),
    );
  }

  ThemeData get darkTheme {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8BD3C7),
      onPrimary: Color(0xFF11202A),
      secondary: Color(0xFFF29774),
      onSecondary: Color(0xFF11202A),
      error: Color(0xFFFF8C78),
      onError: Color(0xFF11202A),
      surface: Color(0xFF111B24),
      onSurface: Color(0xFFF7F0E7),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0D141B),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF7F0E7),
          letterSpacing: -0.3,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: Color(0xFFF7F0E7),
          letterSpacing: -1.2,
          height: 1.05,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF7F0E7),
          letterSpacing: -0.8,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF7F0E7),
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF7F0E7),
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.45,
          color: Color(0xFFD2D9DE),
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Color(0xFFAAB5BC),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF111B24),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: Color(0xFF253240)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF18242D),
        hintStyle: const TextStyle(color: Color(0xFF82909B)),
        labelStyle: const TextStyle(color: Color(0xFFAAB5BC)),
        prefixIconColor: const Color(0xFFAAB5BC),
        suffixIconColor: const Color(0xFFAAB5BC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF8BD3C7), width: 1.4),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF24303B),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFF29774),
        contentTextStyle: const TextStyle(color: Color(0xFF111B24)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: scheme.secondary,
        unselectedItemColor: const Color(0xFF82909B),
      ),
    );
  }

  static const Color primaryBlue = Color(0xFF174D4C);
  static const Color primaryDark = Color(0xFF13232E);
  static const Color accentGreen = Color(0xFF5F9E7A);
  static const Color warningOrange = Color(0xFFF2A65A);
  static const Color errorRed = Color(0xFFBC3C2F);
  static const Color accentCoral = Color(0xFFE9724C);
  static const Color accentSand = Color(0xFFF4EFE6);

  Gradient get appBarGradient => isDarkMode
      ? const LinearGradient(
          colors: [Color(0xFF111B24), Color(0xFF153640)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF174D4C), Color(0xFF2F6C68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  Gradient get shellGradient => isDarkMode
      ? const LinearGradient(
          colors: [Color(0xFF0D141B), Color(0xFF13222C), Color(0xFF172630)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : const LinearGradient(
          colors: [Color(0xFFF4EFE6), Color(0xFFECE3D6), Color(0xFFF8F2EA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

  Gradient get heroGradient => isDarkMode
      ? const LinearGradient(
          colors: [Color(0xFFF29774), Color(0xFF8BD3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFFE9724C), Color(0xFFF2A65A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  Gradient get panelGradient => isDarkMode
      ? const LinearGradient(
          colors: [Color(0xFF111B24), Color(0xFF17222D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFFFFFCF7), Color(0xFFF6F0E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  Color get onlineColor => const Color(0xFF5F9E7A);
  Color get offlineColor =>
      isDarkMode ? const Color(0xFF73808A) : const Color(0xFF88939B);
  Color get awayColor => warningOrange;

  Color get sentMessageColor =>
      isDarkMode ? const Color(0xFFE9724C) : const Color(0xFFE9724C);
  Color get receivedMessageColor =>
      isDarkMode ? const Color(0xFF17222D) : const Color(0xFFFFFCF7);

  Color get sentMessageTextColor =>
      isDarkMode ? const Color(0xFF111B24) : Colors.white;
  Color get receivedMessageTextColor =>
      isDarkMode ? const Color(0xFFF7F0E7) : const Color(0xFF13232E);

  Color get typingIndicatorColor =>
      isDarkMode ? const Color(0xFF8BD3C7) : const Color(0xFF174D4C);
  Color get unreadCountColor => accentCoral;
  Color get unreadCountTextColor => Colors.white;

  Color get chatBackgroundColor =>
      isDarkMode ? const Color(0xFF0F171F) : const Color(0xFFF7F1E8);
  Color get inputBackgroundColor =>
      isDarkMode ? const Color(0xFF18242D) : const Color(0xFFF3EEE4);
  Color get dividerColor =>
      isDarkMode ? const Color(0xFF24303B) : const Color(0xFFE3DDD3);
  Color get surfaceColor =>
      isDarkMode ? const Color(0xFF111B24) : const Color(0xFFFFFCF7);
  Color get surfaceVariantColor =>
      isDarkMode ? const Color(0xFF18242D) : const Color(0xFFF3EEE4);
  Color get primaryTextColor =>
      isDarkMode ? const Color(0xFFF7F0E7) : const Color(0xFF13232E);
  Color get secondaryTextColor =>
      isDarkMode ? const Color(0xFFAAB5BC) : const Color(0xFF66727C);
  Color get hintTextColor =>
      isDarkMode ? const Color(0xFF82909B) : const Color(0xFF7A837F);
  Color get borderColor =>
      isDarkMode ? const Color(0xFF2A3742) : const Color(0xFFD8D1C7);
  Color get shadowColor =>
      isDarkMode ? const Color(0x66000000) : const Color(0x140F1F29);

  Color get shimmerBaseColor =>
      isDarkMode ? const Color(0xFF24303B) : const Color(0xFFE5DED3);
  Color get shimmerHighlightColor =>
      isDarkMode ? const Color(0xFF2B3945) : const Color(0xFFF7F2EA);

  Color get accentColor => accentCoral;
  Color get subtleAccent =>
      isDarkMode ? const Color(0xFF1E313A) : const Color(0xFFE9E2D7);

  Color getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFC44B3E);
      case 'doc':
      case 'docx':
        return const Color(0xFF2962A3);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF4C8A63);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFD1784D);
      case 'zip':
      case 'rar':
        return const Color(0xFF6A5ACD);
      case 'txt':
        return const Color(0xFF8B6B4A);
      default:
        return offlineColor;
    }
  }
}
