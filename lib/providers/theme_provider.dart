import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  bool _isDarkMode;

  ThemeProvider() : _isDarkMode = false {
    _loadPreferences();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  TextTheme get _baseTextTheme => const TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    
    // Headlines
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    
    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    
    // Labels
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    
    // Body
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  );

  ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Roboto', // Set default font
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        textTheme: _baseTextTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        primaryTextTheme: _baseTextTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.indigo.withOpacity(0.2),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Roboto', // Set default font
        cardColor: const Color(0xFF2D2D2D),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF2D2D2D),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white70),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textTheme: _baseTextTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        primaryTextTheme: _baseTextTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF2D2D2D),
          indicatorColor: Colors.indigo.withOpacity(0.3),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(color: Colors.white70),
          ),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF2D2D2D),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white70),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white70,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
