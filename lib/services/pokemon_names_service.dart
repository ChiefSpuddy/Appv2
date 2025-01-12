import 'dart:convert';
import 'package:flutter/services.dart';

class PokemonNamesService {
  List<String> _pokemonNames = [];
  
  Future<void> loadPokemonNames() async {
    try {
      final jsonString = await rootBundle.loadString('assets/names.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _pokemonNames = List<String>.from(jsonData['names']);
    } catch (e) {
      print('Error loading Pokemon names: $e');
      _pokemonNames = [];
    }
  }
  
  List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];
    
    return _pokemonNames
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }
}
