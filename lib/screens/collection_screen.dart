import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collection_service.dart';
import '../widgets/card_item.dart';
import '../providers/theme_provider.dart';
import '../widgets/collection_analytics.dart';
import '../widgets/collection_grid.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../models/custom_collection.dart';  // Add this import
import 'dart:math' show max;  // Add this import
import 'home_screen.dart';
import 'custom_collections_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Add this import

class CollectionScreen extends StatefulWidget {  // Change to StatefulWidget
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _showAnalytics = false;
  static final _authService = AuthService();

  void _switchView(bool showAnalytics) {
    setState(() => _showAnalytics = showAnalytics);
  }

  Widget _buildCustomCollectionsMenuEntry(List<CustomCollection> collections) {
    double totalValue = 0;
    for (var collection in collections) {
      if (collection.totalValue != null) {
        totalValue += collection.totalValue!;
      }
    }

    return PopupMenuItem(
      value: 'custom_collections',
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.collections_bookmark),
        title: const Text('Custom Collections'),
        subtitle: Text(
          '${collections.length} collections • €${totalValue.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not authenticated, show login prompt in a Scaffold
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in to view your collection',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 12,
                      ),
                      child: Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated, show collection
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(
                      Icons.grid_view,
                      color: !_showAnalytics ? Colors.white : Colors.grey[700],
                      size: 20,
                    ),
                    label: Text(
                      'Collection',
                      style: TextStyle(
                        color: !_showAnalytics ? Colors.white : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(
                      Icons.analytics,
                      color: _showAnalytics ? Colors.white : Colors.grey[700],
                      size: 20,
                    ),
                    label: Text(
                      'Analytics',
                      style: TextStyle(
                        color: _showAnalytics ? Colors.white : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                selected: {_showAnalytics},
                onSelectionChanged: (Set<bool> newSelection) {
                  _switchView(newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context).primaryColor.withOpacity(0.9);
                      }
                      return isDark 
                        ? Colors.grey[850]?.withOpacity(0.7) 
                        : Colors.grey[200]?.withOpacity(0.8);
                    },
                  ),
                  side: MaterialStateProperty.all(BorderSide.none),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu),
                constraints: const BoxConstraints(maxWidth: 280),
                onSelected: (value) async {
                  switch (value) {
                    case 'toggle_theme':
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                      break;
                    case 'view_collection':
                      _switchView(false);
                      break;
                    case 'view_analytics':
                      _switchView(true);
                      break;
                    case 'sort_name':
                    case 'sort_price':
                    case 'sort_date':
                      // TODO: Implement sorting
                      break;
                    case 'filter':
                      // TODO: Show filter dialog
                      break;
                    case 'logout':
                      await _authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'toggle_theme',
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
                            ? Icons.light_mode 
                            : Icons.dark_mode
                      ),
                      title: Text(
                        Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                            ? 'Light Mode'
                            : 'Dark Mode'
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'view_collection',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.grid_view),
                      title: const Text('View Collection'),
                      trailing: !_showAnalytics ? const Icon(Icons.check, size: 16) : null,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_analytics',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.analytics),
                      title: const Text('View Analytics'),
                      trailing: _showAnalytics ? const Icon(Icons.check, size: 16) : null,
                    ),
                  ),
                  if (!_showAnalytics) ...[
                    const PopupMenuDivider(),
                    // Sort options
                    PopupMenuItem(
                      value: 'sort_name',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.sort_by_alpha),
                        title: const Text('Sort by Name'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sort_price',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.attach_money),
                        title: const Text('Sort by Price'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sort_date',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Sort by Date'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Filter option
                    PopupMenuItem(
                      value: 'filter',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.filter_list),
                        title: const Text('Filter Cards'),
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Container(
            margin: const EdgeInsets.only(top: 8),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                ),
              ),
              child: _showAnalytics
                ? const CollectionAnalytics()
                : const CollectionGrid(),
            ),
          ),
        );
      },
    );
  }
}
