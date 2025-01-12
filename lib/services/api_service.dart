import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

class ApiService {
  static const _baseUrl = 'https://api.pokemontcg.io/v2';
  static const _headers = {
    'Accept': 'application/json',
    'Access-Control-Allow-Origin': '*',
  };
  
  Future<List<TcgCard>> searchCards(
    String query, {
    String? setNumber,
    String sortBy = 'name',
    bool rareOnly = false,
  }) async {
    var queryParams = <String, dynamic>{
      'q': query,
    };
    
    if (setNumber?.isNotEmpty == true) {
      queryParams['number'] = setNumber;
    }
    
    if (rareOnly) {
      queryParams['rarity'] = 'Rare Holo,Rare Ultra,Rare Secret';
    }
    
    queryParams['orderBy'] = sortBy;
    
    if (query.isEmpty) return [];
    
    try {
      // Use exact name match instead of partial match
      final response = await http.get(
        Uri.parse('$_baseUrl/cards?q=name:"$query"'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((card) => TcgCard.fromJson(card))
            .toList();
      }
      throw Exception('Failed to load cards');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}