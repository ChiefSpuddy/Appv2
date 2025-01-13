import 'package:http/http.dart' as http;
import 'dart:convert';

class PokemonApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';
  static final Map<String, Map<String, dynamic>> _cache = {};

  String _sanitizePokemonName(String name) {
    final formVariants = {
      'wormadam': 'wormadam-plant',
      'giratina': 'giratina-altered',
      'shaymin': 'shaymin-land',
      'basculin': 'basculin-red-striped',
      'darmanitan': 'darmanitan-standard',
      'tornadus': 'tornadus-incarnate',
      'thundurus': 'thundurus-incarnate',
      'landorus': 'landorus-incarnate',
      'keldeo': 'keldeo-ordinary',
      'meloetta': 'meloetta-aria',
      'meowstic': 'meowstic-male',
      'aegislash': 'aegislash-shield',
      'pumpkaboo': 'pumpkaboo-average',
      'gourgeist': 'gourgeist-average',
      'urshifu': 'urshifu-single-strike',
      'zygarde': 'zygarde-50',
      'oricorio': 'oricorio-baile',
      'lycanroc': 'lycanroc-midday',
      'wishiwashi': 'wishiwashi-solo',
      'minior': 'minior-red-meteor',
      'mimikyu': 'mimikyu-disguised',
      'toxtricity': 'toxtricity-amped',
      'eiscue': 'eiscue-ice',
      'indeedee': 'indeedee-male',
      'morpeko': 'morpeko-full-belly',
      'mr. rime': 'mr-rime',
    };

    // Check for form variants
    final normalizedName = name.toLowerCase();
    if (formVariants.containsKey(normalizedName)) {
      return formVariants[normalizedName]!;
    }

    final specialCases = {
      "farfetch'd": "farfetchd",
      "sirfetch'd": "sirfetchd",
      "flabébé": "flabebe",
      "nidoran♀": "nidoran-f",
      "nidoran♂": "nidoran-m",
      "mr. mime": "mr-mime",
      "mime jr.": "mime-jr",
      "type: null": "type-null",
      "jangmo-o": "jangmo-o",
      "hakamo-o": "hakamo-o",
      "kommo-o": "kommo-o",
      "tapu koko": "tapu-koko",
      "tapu lele": "tapu-lele",
      "tapu bulu": "tapu-bulu",
      "tapu fini": "tapu-fini",
      "porygon-z": "porygon-z",
      "ho-oh": "ho-oh",
    };

    // Check for direct special cases first
    final lowerName = name.toLowerCase();
    if (specialCases.containsKey(lowerName)) {
      return specialCases[lowerName]!;
    }

    // Handle form variants
    if (lowerName.contains('-normal') ||
        lowerName.contains('-standard') ||
        lowerName.contains('-land') ||
        lowerName.contains('-incarnate') ||
        lowerName.contains('-ordinary') ||
        lowerName.contains('-aria') ||
        lowerName.contains('-shield') ||
        lowerName.contains('-average') ||
        lowerName.contains('-50')) {
      // Remove the form suffix and everything after it
      return lowerName.split('-')[0];
    }

    // General sanitization
    return lowerName
        .replaceAll(RegExp(r'[^a-z0-9-]'), '') // Remove all special characters except hyphen
        .replaceAll(RegExp(r'-+'), '-')        // Replace multiple hyphens with single hyphen
        .replaceAll(RegExp(r'^-|-$'), '');     // Remove leading/trailing hyphens
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

        // Fix type extraction
        final typesList = (data['types'] as List)
            .map((type) => type['type']['name'].toString())
            .toList();

        final result = {
          'id': data['id'],
          'name': name,
          'spriteUrl': _getSafeImageUrl(data['sprites']),
          'types': typesList, // This is now properly typed as List<String>
          'height': (data['height'] as num) / 10, // Convert to meters
          'weight': (data['weight'] as num) / 10, // Convert to kg
          'abilities': (data['abilities'] as List).map((ability) {
            return ability['ability']['name'].toString();
          }).toList(),
          'stats': {
            'hp': data['stats'][0]['base_stat'] as int,
            'attack': data['stats'][1]['base_stat'] as int,
            'defense': data['stats'][2]['base_stat'] as int,
            'spAtk': data['stats'][3]['base_stat'] as int,
            'spDef': data['stats'][4]['base_stat'] as int,
            'speed': data['stats'][5]['base_stat'] as int,
          },
          'flavorText': _getFlavorText(speciesData),
        };

        // Cache the result
        _cache[name] = result;
        return result;
      }
      throw Exception('Failed to load pokemon: ${response.statusCode}');
    } catch (e) {
      print('Error fetching pokemon details for $name: $e');
      // Return a safe fallback with proper types
      return {
        'id': 0,
        'name': name,
        'spriteUrl': null,
        'types': <String>[], // Explicitly typed empty list
        'height': 0.0,
        'weight': 0.0,
        'abilities': <String>[],
        'stats': {
          'hp': 0,
          'attack': 0,
          'defense': 0,
          'spAtk': 0,
          'spDef': 0,
          'speed': 0,
        },
        'flavorText': 'No description available.',
      };
    }
  }

  String _getFlavorText(Map<String, dynamic> speciesData) {
    try {
      final entries = speciesData['flavor_text_entries'] as List;
      final englishEntry = entries.firstWhere(
        (entry) => entry['language']['name'] == 'en',
        orElse: () => {'flavor_text': 'No description available.'},
      );
      return (englishEntry['flavor_text'] as String)
          .replaceAll('\n', ' ')
          .replaceAll('\f', ' ');
    } catch (e) {
      return 'No description available.';
    }
  }

  Future<List<String>> getPokemonByType(String type) async {
    if (type.toLowerCase() == 'all') {
      return []; // Return empty list for 'All' type
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/type/${type.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pokemonList = (data['pokemon'] as List)
            .map((p) => p['pokemon']['name'] as String)
            .toList();
        
        // Convert API names back to display names (capitalize first letter)
        return pokemonList.map((name) => name
          .split('-')[0] // Remove form names
          .split('_') // Split by underscore
          .map((word) => word[0].toUpperCase() + word.substring(1)) // Capitalize
          .join(' ')) // Join with spaces
          .toList();
      }
      throw Exception('Failed to load pokemon by type: ${response.statusCode}');
    } catch (e) {
      print('Error fetching pokemon by type $type: $e');
      return [];
    }
  }
}
