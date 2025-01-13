import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';

class PokemonCollectionService {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final CollectionReference collection = FirebaseFirestore.instance.collection('cards');

  Future<Map<String, dynamic>> getPokemonStats(String pokemonName) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final cards = await collection
          .doc(userId)
          .collection('userCards')
          .where('name', isGreaterThanOrEqualTo: pokemonName)
          .where('name', isLessThan: '${pokemonName}z')
          .get();

      final totalValue = cards.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['price'] as num? ?? 0).toDouble(),
      );

      return {
        'cardCount': cards.docs.length,
        'totalValue': totalValue,
        'variants': cards.docs.map((doc) => doc.data()['setName']).toSet().length,
        'cards': cards.docs.map((doc) => TcgCard(
          id: doc.data()['id'],
          name: doc.data()['name'],
          imageUrl: doc.data()['imageUrl'],
          setName: doc.data()['setName'],
          rarity: doc.data()['rarity'],
          price: doc.data()['price']?.toDouble(),
        )).toList(),
      };
    } catch (e) {
      print('Error getting Pokemon stats: $e');
      return {
        'cardCount': 0,
        'totalValue': 0.0,
        'variants': 0,
        'cards': <TcgCard>[],
      };
    }
  }
}
