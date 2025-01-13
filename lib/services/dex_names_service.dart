import 'dart:convert';
import 'package:flutter/services.dart';

class DexNamesService {
  List<String> _dexNames = [];
  bool _isLoaded = false;

  Future<List<String>> loadDexNames() async {
    if (_isLoaded) return _dexNames;
    try {
      final jsonString = await rootBundle.loadString('assets/names.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _dexNames = List<String>.from(jsonData['names']);
      _isLoaded = true;
      return _dexNames;
    } catch (e) {
      print('Error loading dex names: $e');
      return [];
    }
  }

  List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];
    query = query.toLowerCase();
    return _dexNames
        .where((name) => name.toLowerCase().contains(query))
        .take(5)
        .toList();
  }
}
