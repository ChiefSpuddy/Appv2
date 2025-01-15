import 'dart:convert';
import 'dart:math';
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

  Map<String, String> get sortFieldMap => {
    'price:asc': 'cardmarket.prices.averageSellPrice',
    'price:desc': '-cardmarket.prices.averageSellPrice',
    'name:asc': 'name',
    'name:desc': '-name',
    'number:asc': 'number',
    'number:desc': '-number',
    'date:asc': 'set.releaseDate',
    'date:desc': '-set.releaseDate',
  };

  // Add this getter for special search keywords
  static List<Map<String, dynamic>> get quickSearchKeywords => [
    {
      'name': 'Vintage',
      'icon': '🏆',
      'query': '(set.series:"Base" or set.series:"Gym" or set.series:"Neo" or set.series:"Legendary" or set.series:"Rocket")',
      'description': 'WOTC Era Cards',
    },
    {
      'name': 'Special Illustration',
      'icon': '💎',
      'query': '(rarity:"Special Illustration Rare" or rarity:"Special Art Rare") set.series:"Scarlet & Violet"',
      'description': 'Special Illustration Rare Cards (Modern)',
    },
    {
      'name': 'Promos',
      'icon': '🌟',
      'query': 'set.series:"Promo"',
      'description': 'Promotional Cards',
    },
    {
      'name': 'Full Art',
      'icon': '🎨',
      'query': 'subtypes:"Full Art"',
      'description': 'Full Art Cards',
    },
  ];

  Future<Map<String, dynamic>> searchCards(
    String query, {
    String sortBy = 'name:asc',
    bool rareOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (query.trim().isEmpty) return {'cards': [], 'totalCount': 0};

    try {
      final cacheKey = _generateCacheKey(query, '', sortBy, rareOnly, page, pageSize);
      
      if (_isCacheValid(cacheKey) && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }

      // Check for special keywords first
      final specialSearch = quickSearchKeywords.firstWhere(
        (k) => k['name'].toLowerCase() == query.toLowerCase(),
        orElse: () => {'query': ''},
      );

      // Check if the query is a set name from quickSearchSets
      final isSetSearch = quickSearchSets.any(
        (set) => set['name']!.toLowerCase() == query.toLowerCase()
      );

      // Build search query string
      var searchQuery = specialSearch['query'].isNotEmpty
          ? specialSearch['query']
          : isSetSearch 
              ? 'set.name:"$query"'
              : 'name:"*${query.trim()}*"';
      
      if (rareOnly) {
        searchQuery += ' (rarity:rare or rarity:"rare holo" or rarity:"rare ultra")';
      }

      // Simplify sort handling
      final orderBy = sortFieldMap[sortBy] ?? 'name';

      final url = Uri.parse('$_baseUrl/cards').replace(
        queryParameters: {
          'q': searchQuery,
          'orderBy': orderBy,
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'select': 'id,name,number,set,rarity,cardmarket,images',
        },
      );

      final headers = Map<String, String>.from(_headers);
      // Update CORS headers
      headers.addAll({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Api-Key',
        'Referrer-Policy': 'no-referrer',
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

        // Cache the result with the generated key
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

  // Add this static getter for quick search sets
  static List<Map<String, String>> get quickSearchSets => [
    {
      'name': 'Prismatic Evolutions',
      'icon': '💫',
      'releaseDate': '2024-03-22',
    },
    {
      'name': 'Surging Sparks',
      'icon': '⚡',
      'releaseDate': '2024-01-26',
    },
    {
      'name': 'Paradox Rift',
      'icon': '🌀',
      'releaseDate': '2023-11-03',
    },
    {
      'name': 'Paldea Evolved',
      'icon': '🌟',
      'releaseDate': '2023-06-30',
    },
    {
      'name': 'Scarlet & Violet',
      'icon': '🔮',
      'releaseDate': '2023-03-31',
    },
    // Add more sets as needed
  ];

  Future<Map<String, dynamic>?> getCardPricing(String cardId) async {
    try {
      final url = Uri.parse('$_baseUrl/cards/$cardId');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final cardmarket = data['cardmarket'];
        
        if (cardmarket == null) return null;

        // Get all available price data
        return {
          'prices': {
            'averageSellPrice': cardmarket['prices']?['averageSellPrice'],
            'lowPrice': cardmarket['prices']?['lowPrice'],
            'trendPrice': cardmarket['prices']?['trendPrice'],
            'germanProLow': cardmarket['prices']?['germanProLow'],
            'suggestedPrice': cardmarket['prices']?['suggestedPrice'],
            'reverseHoloTrend': cardmarket['prices']?['reverseHoloTrend'],
            'reverseHoloLow': cardmarket['prices']?['reverseHoloLow'],
            'reverseHoloSell': cardmarket['prices']?['reverseHoloSell'],
            'avg1': cardmarket['prices']?['avg1'],
            'avg7': cardmarket['prices']?['avg7'],
            'avg30': cardmarket['prices']?['avg30'],
          },
          'updatedAt': cardmarket['updatedAt'],
          'url': cardmarket['url'],
          'lastEdited': cardmarket['lastEdited'],
        };
      }
      return null;
    } catch (e) {
      print('Error fetching card pricing: $e');
      return null;
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
      setNumber: card['number'] ?? '',
      releaseDate: _parseDate(card['set']?['releaseDate']?.toString()),
    )).toList();
  }

  // Update sort field mapping
  Map<String, String> get _sortFieldMap => {
    'price': 'cardmarket.prices.averageSellPrice',
    'name': 'name',
    'number': 'number',
    'date': 'set.releaseDate',
  };

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

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      // First try standard ISO format
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try parsing date with forward slashes
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month
            int.parse(parts[2]), // day
          );
        }
      } catch (e) {
        print('Error parsing date: $dateStr');
      }
      return null;
    }
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