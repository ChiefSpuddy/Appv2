import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

// Move SearchQuery class outside of ApiService
class SearchQuery {
  final String name;
  final String? number;
  SearchQuery(this.name, this.number);
}

class ApiService {
  static const _baseUrl = 'https://api.pokemontcg.io/v2';
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const _cacheDuration = Duration(hours: 24);
  static DateTime? _lastRequestTime;
  static const _requestDelay = Duration(milliseconds: 100);
  
  // Add these static members
  static const List<int> pageSizes = [20, 40, 60, 80, 100];
  static const int defaultPageSize = 20;  // Changed from 25 to 20
  
  // Update headers to include API key
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Api-Key': 'eebb53a0-319a-4231-9244-fd7ea48b5d2c', // Add your API key here
  };

  Future<Map<String, dynamic>> searchCards(
    String query, {
    String sortBy = 'name',
    bool rareOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final searchParts = _parseSearchQuery(query.trim());
    final cacheKey = _generateCacheKey(searchParts.name, searchParts.number ?? '', sortBy, rareOnly, page, pageSize);
    
    if (_isCacheValid(cacheKey)) return _cache[cacheKey]!;
    if (searchParts.name.isEmpty) return {'cards': [], 'totalCount': 0};

    await _throttleRequest();

    try {
      // Build search query differently
      var searchTerms = [];
      
      // Add name search
      searchTerms.add('name:"*${searchParts.name}*"');
      
      // Only add number if it exists and is valid
      if (searchParts.number?.isNotEmpty ?? false) {
        // Remove any spaces but keep special characters for set numbers
        final cleanNumber = searchParts.number!.replaceAll(' ', '');
        searchTerms.add('number:$cleanNumber');
      }

      if (rareOnly) {
        searchTerms.add('(rarity:rare or rarity:"rare holo" or rarity:"rare ultra")');
      }

      final searchQuery = searchTerms.join(' ');

      final url = Uri.parse('$_baseUrl/cards').replace(
        queryParameters: {
          'q': searchQuery,
          'orderBy': sortBy,
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          // Update select fields to avoid CORS issues with images
          'select': 'id,name,number,set,rarity,cardmarket,images',
        },
      );

      final headers = Map<String, String>.from(_headers);
      // Add CORS headers
      headers.addAll({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Api-Key',
      });

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = {
          'cards': _parseCards(data['data']),
          'totalCount': data['totalCount'] ?? 0,
          'page': data['page'] ?? page,
          'pageSize': data['pageSize'] ?? pageSize,
        };

        // Cache the result
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return result;
      }
      
      print('API Error ${response.statusCode}: ${response.body}');
      return {'cards': [], 'totalCount': 0};
    } catch (e) {
      print('Error searching cards: $e');
      return {'cards': [], 'totalCount': 0};
    }
  }

  SearchQuery _parseSearchQuery(String query) {
    // Match patterns like:
    // - "Pikachu 58/102"
    // - "Dark Charizard 4/82"
    // - "Mewtwo 10"
    // - "Pikachu TG58"
    final regexPatterns = [
      RegExp(r'^(.*?)\s+(\d+(?:\/\d+)?)\s*$'),  // Standard set numbers (58/102)
      RegExp(r'^(.*?)\s+([A-Z]+\d+)\s*$'),       // Special set numbers (TG58)
      RegExp(r'^(.*?)\s+(\d+)\s*$'),             // Simple numbers (10)
    ];

    for (var regex in regexPatterns) {
      final match = regex.firstMatch(query);
      if (match != null) {
        return SearchQuery(match.group(1)!.trim(), match.group(2));
      }
    }

    // No set number found, treat entire query as name
    return SearchQuery(query, null);
  }

  List<TcgCard> _parseCards(List<dynamic> data) {
    return data.map((card) => TcgCard(
      id: card['id'],
      name: card['name'],
      imageUrl: card['images']['small'],
      setName: card['set']?['name'] ?? 'Unknown Set',
      rarity: card['rarity'] ?? 'Unknown',
      price: _parsePrice(card['cardmarket']?['prices']?['averageSellPrice']),
    )).toList();
  }

  String _generateCacheKey(
    String query,
    String setNumber,  // Changed from String? to String
    String sortBy,
    bool rareOnly,
    int page,
    int pageSize,
  ) {
    return '$query|$setNumber|$sortBy|$rareOnly|$page|$pageSize';
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  Future<void> _throttleRequest() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _requestDelay) {
        await Future.delayed(_requestDelay - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  double? _parsePrice(dynamic price) {
    if (price == null) return null;
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price);
    return null;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheDuration)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}