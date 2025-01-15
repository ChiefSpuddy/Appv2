import 'package:flutter/material.dart';
import 'widgets/collection_analytics.dart';  // Add this import

// ...existing code...

  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const HomeScreen(),
    '/search': (context) => const SearchScreen(),
    '/analytics': (context) => const CollectionAnalytics(),  // Add this line
    '/profile': (context) => const ProfileScreen(),
    // ...other existing routes...
  };

// ...existing code...
