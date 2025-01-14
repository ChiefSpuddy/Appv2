import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import '../widgets/portfolio_value_card.dart';

class HomeOverview extends StatelessWidget {
  const HomeOverview({super.key});

  void _navigateToIndex(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<HomeScreenState>();
    if (state != null) {
      state.onNavItemTapped(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Section with Gradient Background
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context).primaryColor,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sign In button (if not authenticated)
                      if (!snapshot.hasData)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.login, color: Colors.white),
                            label: const Text('Sign In', style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            ),
                          ),
                        ),
                      Text(
                        '🎴 Welcome to TCG Collection Manager',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Manage your collection, track your Pokémon Dex progress, and analyze your cards',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Portfolio Value Card with custom margin
                      if (snapshot.hasData)
                        const PortfolioValueCard(
                          showCardCount: false,
                          margin: EdgeInsets.symmetric(vertical: 8),
                        ),
                      const SizedBox(height: 24),
                      // Quick Access Cards Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,  // Reduced from 12
                        crossAxisSpacing: 8,  // Reduced from 12
                        childAspectRatio: 1.3,  // No change
                        padding: EdgeInsets.zero,  // Remove padding
                        children: [
                          _buildQuickAccessCard(
                            context,
                            icon: Icons.search,
                            title: 'Search Cards',
                            description: 'Browse and find cards to add',
                            color: Colors.blue,
                            onTap: () => _navigateToIndex(context, 1),
                          ),
                          _buildQuickAccessCard(
                            context,
                            icon: Icons.collections,
                            title: 'My Collection',
                            description: 'View and manage your cards',
                            color: Colors.green,
                            onTap: () => _navigateToIndex(context, 2),
                          ),
                          _buildQuickAccessCard(
                            context,
                            icon: Icons.catching_pokemon,
                            title: 'Pokémon Dex',
                            description: 'Track your Dex completion',
                            color: Colors.orange,
                            onTap: () => _navigateToIndex(context, 3),
                          ),
                          _buildQuickAccessCard(
                            context,
                            icon: Icons.analytics,
                            title: 'Analytics',
                            description: 'Collection insights and stats',
                            color: Colors.purple,
                            onTap: () => _navigateToIndex(context, 4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Features Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Features',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        context,
                        icon: Icons.catching_pokemon,
                        title: 'Pokémon Dex Tracking',
                        description: 'Keep track of your Pokémon collection progress with our new Dex feature',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.analytics_outlined,
                        title: 'Advanced Analytics',
                        description: 'Get detailed insights about your collection value and rarity distribution',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.cloud_sync,
                        title: 'Cloud Sync',
                        description: 'Your collection is automatically backed up and synced across devices',
                      ),
                    ],
                  ),
                ),
                // Quick Tips Section
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Tips',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildTipCard(
                        context,
                        tip: '💡 Use filters in the search to find specific card types',
                        action: 'Try Search',
                        onTap: () => _navigateToIndex(context, 1),
                      ),
                      _buildTipCard(
                        context,
                        tip: '📊 Check your collection analytics for investment insights',
                        action: 'View Collection',
                        onTap: () => _navigateToIndex(context, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adjustedColor = isDark 
        ? Color.lerp(color, Colors.white, 0.2)! 
        : color;
        
    return Card(
      elevation: 2,  // Reduced from 4
      shadowColor: adjustedColor.withOpacity(0.3),  // Reduced opacity
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),  // Reduced from 16
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),  // Match card border radius
        child: Container(
          padding: const EdgeInsets.all(8),  // Reduced from 12
          decoration: BoxDecoration(
            color: isDark 
                ? adjustedColor.withOpacity(0.1)
                : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),  // Reduced from 8
                decoration: BoxDecoration(
                  color: adjustedColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,  // Slightly larger icon
                  color: adjustedColor,
                ),
              ),
              const SizedBox(height: 6),  // Reduced from 8
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,  // Increased from 12
                  fontWeight: FontWeight.w600,  // Bolder
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reduced from 4
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,  // Increased from 10
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.1,  // Tighter line height
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.blue.withOpacity(0.2)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: isDark ? Colors.blue[300] : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required String tip,
    required String action,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(tip, style: Theme.of(context).textTheme.bodyMedium),
              ),
              TextButton(
                onPressed: onTap,
                child: Text(action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
