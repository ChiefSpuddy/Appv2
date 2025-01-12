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

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  // Change to static final
  static final _authService = AuthService();

  void _switchTab(BuildContext context, int index) {
    final controller = DefaultTabController.of(context);
    if (controller != null) {
      controller.animateTo(index);
    } else {
      debugPrint('TabController not found');
    }
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
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              title: Text(
                'My Collection',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
              ),
              bottom: const TabBar(
                // Make tabs more compact
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.symmetric(vertical: 4),
                tabs: [
                  Tab(text: 'Collection'),
                  Tab(text: 'Analytics'),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  constraints: const BoxConstraints(maxWidth: 280), // Prevent overflow
                  onSelected: (value) async {
                    switch (value) {
                      case 'toggle_theme':
                        // Simply toggle theme without navigation
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                        break;
                      case 'view_grid':
                        _switchTab(context, 0);
                        break;
                      case 'analytics':
                        _switchTab(context, 1);
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
                        await CollectionScreen._authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                        break;
                      case 'custom_collections':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomCollectionsScreen(),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    // Add this as the first menu item
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
                      value: 'view_grid',
                      child: ListTile( // Use ListTile for better spacing
                        dense: true,
                        leading: const Icon(Icons.grid_view),
                        title: const Text('View Collection'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'analytics',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.analytics),
                        title: const Text('View Analytics'),
                      ),
                    ),
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
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'custom_collections',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.collections_bookmark),
                        title: const Text('Custom Collections'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Logout option
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
                child: const TabBarView(
                  children: [
                    CollectionGrid(),
                    CollectionAnalytics(),
                  ],
                ),
              ),
            ),
            // Remove the floatingActionButton property
          ),
        );
      },
    );
  }
}
