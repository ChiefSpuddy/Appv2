class CollectorLevel {
  final int level;
  final int currentXp;
  final int requiredXp;
  final Map<String, int> bonuses;
  final List<String> unlockedPerks;
  final Map<String, double> multipliers;

  CollectorLevel({
    required this.level,
    required this.currentXp,
    required this.requiredXp,
    required this.bonuses,
    required this.unlockedPerks,
    this.multipliers = const {},
  });

  double get progress => currentXp / requiredXp;
  int get remainingXp => requiredXp - currentXp;
  
  // XP required for next level uses a logarithmic curve
  static int calculateRequiredXp(int level) {
    return (100 * (1 + (level * 0.5))).round();
  }
}
