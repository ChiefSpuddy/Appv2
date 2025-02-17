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
import 'package:lottie/lottie.dart';  // Add this import

class CollectionScreen extends StatefulWidget {  // Change to StatefulWidget
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // 0: Collection, 1: Analytics, 2: Custom Collections
  static final _authService = AuthService();
  late final AnimationController _animationController; // Add this

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Increased from 5 to 8 seconds
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _switchView(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
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
          backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: isDark ? Colors.black : Theme.of(context).appBarTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,  // Add this to remove any material 3 tint
            centerTitle: true, // Add this line to center the title
            title: ConstrainedBox(  // Wrap in ConstrainedBox for width control
              constraints: const BoxConstraints(maxWidth: 400),  // Limit max width
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),  // Remove left padding
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(
                        Icons.account_balance_wallet,
                        color: _selectedIndex == 0 
                            ? Colors.white  // Always white when selected
                            : isDark ? Colors.grey[300] : Colors.grey[800],
                        size: 22,
                      ),
                      label: const Text('Portfolio'),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: Icon(
                        Icons.analytics,
                        color: _selectedIndex == 1
                            ? Colors.white  // Always white when selected
                            : isDark ? Colors.grey[300] : Colors.grey[800],
                        size: 22,
                      ),
                      label: const Text('Analytics'),
                    ),
                    ButtonSegment<int>(
                      value: 2,
                      icon: Icon(
                        Icons.collections_bookmark,
                        color: _selectedIndex == 2
                            ? Colors.white  // Always white when selected
                            : isDark ? Colors.grey[300] : Colors.grey[800],
                        size: 22,
                      ),
                      label: const Text('Collections'),
                    ),
                  ],
                  selected: {_selectedIndex},
                  onSelectionChanged: (Set<int> newSelection) {
                    final index = newSelection.first;
                    _switchView(index);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.green.shade600;  // Change to green
                        }
                        return isDark 
                          ? Colors.black  // Changed from Colors.grey[850]
                          : Colors.grey[200]?.withOpacity(0.8);
                      },
                    ),
                    side: MaterialStateProperty.resolveWith<BorderSide>(
                      (states) {
                        if (states.contains(MaterialState.selected)) {
                          return BorderSide.none;
                        }
                        return BorderSide(
                          color: isDark ? Colors.white30 : Colors.black26,
                          width: 1.0,
                        );
                      },
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),  // Reduce padding
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      _switchView(0);
                      break;
                    case 'view_analytics':
                      _switchView(1);
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
                    case 'custom_collections':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomCollectionsScreen(),
                        ),
                      );
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
                      trailing: _selectedIndex == 0 ? const Icon(Icons.check, size: 16) : null,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_analytics',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.analytics),
                      title: const Text('View Analytics'),
                      trailing: _selectedIndex == 1 ? const Icon(Icons.check, size: 16) : null,
                    ),
                  ),
                  if (_selectedIndex == 0) ...[
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
                  PopupMenuItem<String>(
                    value: 'custom_collections',
                    child: StreamBuilder<List<CustomCollection>>(
                      stream: CollectionService().getCustomCollectionsStream(),
                      builder: (context, snapshot) {
                        final collections = snapshot.data ?? [];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.collections_bookmark),
                          title: const Text('Custom Collections'),
                          subtitle: Text(
                            '${collections.length} collections • €${collections.fold<double>(0, (sum, c) => sum + (c.totalValue ?? 0)).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
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
          // Remove or comment out this FAB since it's handled in CollectionGrid
          // floatingActionButton: FloatingActionButton.small(
          //   onPressed: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const CustomCollectionsScreen(),
          //     ),
          //   ),
          //   tooltip: 'Custom Collections',
          //   child: const Icon(Icons.collections_bookmark, size: 20),
          // ),
          body: Stack(  // Wrap the body in a Stack
            children: [
              // Add Lottie background
              if (_selectedIndex != 2) // Don't show on custom collections view
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3, // Increased from 0.15
                    child: Lottie.asset(
                      'assets/animations/background.json',
                      fit: BoxFit.cover,
                      repeat: true,
                      frameRate: FrameRate(30),
                      options: LottieOptions(
                        enableMergePaths: false,
                      ),
                      controller: _animationController,
                    ),
                  ),
                ),
              // Existing animated switcher
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _selectedIndex == 1
                  ? const CollectionAnalytics()
                  : _selectedIndex == 2
                    ? const CustomCollectionsScreen()
                    : const CollectionGrid(),
              ),
            ],
          ),
        );
      },
    );
  }
}
