import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'collection_screen.dart';
import 'home_overview.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dex_collection_screen.dart';  // Update this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static void navigateToSearch(BuildContext context) {
    final state = context.findAncestorStateOfType<HomeScreenState>();
    if (state != null) {
      state.onNavItemTapped(1); // Switch to search tab
    }
  }

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeOverview(),
    SearchScreen(),
    CollectionScreen(),
    DexCollectionScreen(),  // Update this line
    ProfileScreen(),  // Now this will work with const
  ];

  void onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: onNavItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: 'Collection',
          ),
          NavigationDestination(
            icon: Icon(Icons.catching_pokemon),
            selectedIcon: Icon(Icons.catching_pokemon),
            label: 'Dex',  // Changed from 'Pokémon'
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
