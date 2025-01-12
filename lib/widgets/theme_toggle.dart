import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return ListTile(
      leading: Icon(
        themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).iconTheme.color,
      ),
      title: Text(
        themeService.isDarkMode ? 'Dark Mode' : 'Light Mode',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Switch(
        value: themeService.isDarkMode,
        onChanged: (_) => themeService.toggleTheme(),
      ),
    );
  }
}
