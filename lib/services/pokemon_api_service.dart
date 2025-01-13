import 'package:http/http.dart' as http;
import 'dart:convert';

class PokemonApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';
  static final Map<String, Map<String, dynamic>> _cache = {};

  String _sanitizePokemonName(String name) {
    // Handle special cases
    switch (name) {
      case 'Nidoran♀':
        return 'nidoran-f';
      case 'Nidoran♂':
        return 'nidoran-m';
      case 'Mr. Mime':
        return 'mr-mime';
      case 'Farfetch\'d':
        return 'farfetchd';
      case 'Sirfetch\'d':
        return 'sirfetchd';
      default:
        return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    }
  }

  String? _getSafeImageUrl(Map<String, dynamic> sprites) {
    // Use standard sprite instead of artwork to avoid CORS issues
    final frontDefault = sprites['front_default'];
    if (frontDefault != null) {
      // Use the direct PokeAPI sprite URL which doesn't have CORS issues
      return frontDefault.toString();
    }
    
    // Fallback to null if no sprite available
    return null;
  }

  Future<Map<String, dynamic>> getPokemonDetails(String name) async {
    // Check cache first
    if (_cache.containsKey(name)) {
      return _cache[name]!;
    }

    try {
      final sanitizedName = _sanitizePokemonName(name);
      final response = await http.get(
        Uri.parse('$baseUrl/pokemon/$sanitizedName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final speciesResponse = await http.get(
          Uri.parse(data['species']['url']),
        );
        final speciesData = json.decode(speciesResponse.body);

        final result = {
          'id': data['id'],
          'name': name,
          'spriteUrl': _getSafeImageUrl(data['sprites']),
          'types': List<String>.from(
            data['types'].map((type) => type['type']['name']),
          ),
          'height': data['height'] / 10, // Convert to meters
          'weight': data['weight'] / 10, // Convert to kg
          'abilities': List<String>.from(
            data['abilities'].map((ability) => ability['ability']['name']),
          ),
          'stats': {
            'hp': data['stats'][0]['base_stat'],
            'attack': data['stats'][1]['base_stat'],
            'defense': data['stats'][2]['base_stat'],
            'spAtk': data['stats'][3]['base_stat'],
            'spDef': data['stats'][4]['base_stat'],
            'speed': data['stats'][5]['base_stat'],
          },
          'flavorText': speciesData['flavor_text_entries']
              .firstWhere(
                (entry) => entry['language']['name'] == 'en',
                orElse: () => {'flavor_text': 'No description available.'},
              )['flavor_text']
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' '),
        };

        // Cache the result
        _cache[name] = result;
        return result;
      }
      throw Exception('Failed to load pokemon');
    } catch (e) {
      print('Error fetching pokemon details for $name: $e');
      return {
        'spriteUrl': null,
        'types': [],
        'stats': {
          'hp': 0,
          'attack': 0,
          'defense': 0,
          'spAtk': 0,
          'spDef': 0,
          'speed': 0,
        },
      };
    }
  }
}
