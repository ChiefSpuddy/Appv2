import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Fixed import

class ThemeService extends ChangeNotifier {
  late SharedPreferences _prefs;  // Mark as late
  static const String _themeKey = 'isDarkMode';

  ThemeService() {  // Remove prefs parameter
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void _loadTheme() {
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,  // Change from blue to green
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.green.shade600,  // Add this
      foregroundColor: Colors.white,  // Add this
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,  // Change from blue to green
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.green.shade600,  // Add this
      foregroundColor: Colors.white,  // Add this
    ),
    scaffoldBackgroundColor: Colors.black,  // Changed to black
    canvasColor: Colors.black,  // Add this
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.black,  // Explicitly set to black
      surfaceTintColor: Colors.black, // Add this to ensure no color tint
      systemOverlayStyle: SystemUiOverlayStyle.light,  // Add this
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
