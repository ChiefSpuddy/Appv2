import 'dart:convert';
import 'package:flutter/services.dart';

class PokemonNamesService {
  List<String> _pokemonNames = [];
  bool _isLoaded = false;

  Future<void> loadPokemonNames() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/names.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _pokemonNames = List<String>.from(jsonData['names']);
      _isLoaded = true;
    } catch (e) {
      print('Error loading Pokemon names: $e');
      _pokemonNames = [];
    }
  }

  List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];
    query = query.toLowerCase();
    return _pokemonNames
        .where((name) => name.toLowerCase().contains(query))
        .take(5)
        .toList();
  }
}
