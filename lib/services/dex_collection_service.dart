import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';

class DexCollectionService {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final CollectionReference collection = FirebaseFirestore.instance.collection('cards');

  Future<Map<String, dynamic>> getDexStats(String dexName) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final cards = await collection
          .doc(userId)
          .collection('userCards')
          .where('name', isGreaterThanOrEqualTo: dexName)
          .where('name', isLessThan: '${dexName}z')
          .get();

      // ...existing calculation code...
      return {
        'cardCount': cards.docs.length,
        'totalValue': cards.docs.fold<double>(
          0,
          (sum, doc) => sum + (doc.data()['price'] as num? ?? 0).toDouble(),
        ),
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
      print('Error getting dex stats: $e');
      return {
        'cardCount': 0,
        'totalValue': 0.0,
        'variants': 0,
        'cards': <TcgCard>[],
      };
    }
  }
}
