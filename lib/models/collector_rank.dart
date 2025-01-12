import 'package:flutter/material.dart';

class CollectorRank {
  final String title;
  final String icon;
  final int minLevel;
  final int maxLevel;
  final Color color;

  const CollectorRank({
    required this.title,
    required this.icon,
    required this.minLevel,
    required this.maxLevel,
    required this.color,
  });

  static const List<CollectorRank> ranks = [
    CollectorRank(
      title: 'Card Initiate',
      icon: '🃏',
      minLevel: 0,
      maxLevel: 10,
      color: Colors.grey,
    ),
    CollectorRank(
      title: 'Deck Artisan',
      icon: '🎴',
      minLevel: 11,
      maxLevel: 20,
      color: Colors.green,
    ),
    CollectorRank(
      title: 'Relic Seeker',
      icon: '🔍',
      minLevel: 21,
      maxLevel: 30,
      color: Colors.blue,
    ),
    CollectorRank(
      title: 'Artifact Explorer',
      icon: '🧭',
      minLevel: 31,
      maxLevel: 40,
      color: Colors.purple,
    ),
    CollectorRank(
      title: 'Gem Protector',
      icon: '💎',
      minLevel: 41,
      maxLevel: 50,
      color: Colors.teal,
    ),
    CollectorRank(
      title: 'Hoard Commander',
      icon: '👑',
      minLevel: 51,
      maxLevel: 60,
      color: Colors.amber,
    ),
    CollectorRank(
      title: 'Trove Guardian',
      icon: '🛡️',
      minLevel: 61,
      maxLevel: 70,
      color: Colors.red,
    ),
    CollectorRank(
      title: 'Nexus Conqueror',
      icon: '⚔️',
      minLevel: 71,
      maxLevel: 80,
      color: Colors.pink,
    ),
    CollectorRank(
      title: 'Archive Master',
      icon: '📚',
      minLevel: 81,
      maxLevel: 90,
      color: Colors.deepPurple,
    ),
    CollectorRank(
      title: 'Collector Supreme',
      icon: '✨',
      minLevel: 91,
      maxLevel: 100,
      color: Colors.orange,
    ),
  ];

  static CollectorRank getRankForLevel(int level) {
    return ranks.firstWhere(
      (rank) => level >= rank.minLevel && level <= rank.maxLevel,
      orElse: () => ranks.last,
    );
  }
}
