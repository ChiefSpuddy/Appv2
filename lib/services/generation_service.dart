import 'package:flutter/material.dart';

class GenerationService {
  static const Map<String, List<int>> generations = {
    'Gen 1': [1, 151],
    'Gen 2': [152, 251],
    'Gen 3': [252, 386],
    'Gen 4': [387, 493],
    'Gen 5': [494, 649],
    'Gen 6': [650, 721],
    'Gen 7': [722, 809],
    'Gen 8': [810, 905],
    'Gen 9': [906, 1025],
  };

  static String getGeneration(int dexNumber) {
    for (var entry in generations.entries) {
      if (dexNumber >= entry.value[0] && dexNumber <= entry.value[1]) {
        return entry.key;
      }
    }
    return 'Unknown';
  }

  static Color getGenerationColor(String generation) {
    switch (generation) {
      case 'Gen 1': return const Color(0xFFFF1111);
      case 'Gen 2': return const Color(0xFFFFD733);
      case 'Gen 3': return const Color(0xFF00AA00);
      case 'Gen 4': return const Color(0xFF0000FF);
      case 'Gen 5': return const Color(0xFF666666);
      case 'Gen 6': return const Color(0xFFFF00FF);
      case 'Gen 7': return const Color(0xFFFF6600);
      case 'Gen 8': return const Color(0xFF00FFFF);
      case 'Gen 9': return const Color(0xFF9933FF);
      default: return const Color(0xFF999999);
    }
  }

  static List<String> filterByGeneration(List<String> names, String generation) {
    if (generation == 'All') return names;
    
    final range = generations[generation];
    if (range == null) return names;
    
    final startIdx = range[0] - 1;
    final endIdx = range[1] - 1;
    
    if (startIdx >= names.length) return [];
    
    return names.sublist(
      startIdx,
      endIdx < names.length ? endIdx + 1 : names.length,
    );
  }
}
