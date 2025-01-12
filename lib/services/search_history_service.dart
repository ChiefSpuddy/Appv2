import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchHistoryService {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final CollectionReference collection = FirebaseFirestore.instance.collection('users');
  static const int maxSearches = 5;

  Future<void> addSearch(String query) async {
    if (userId.isEmpty || query.trim().isEmpty) return;

    try {
      final doc = collection.doc(userId);
      final searchesRef = doc.collection('searches');
      
      // Add new search with timestamp
      await searchesRef.add({
        'query': query.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get all searches and keep only the most recent ones
      final snapshots = await searchesRef
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshots.docs.length > maxSearches) {
        final toDelete = snapshots.docs.sublist(maxSearches);
        for (var doc in toDelete) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  Future<void> saveSearch(String query, {String? imageUrl}) async {
    if (userId.isEmpty || query.trim().isEmpty) return;

    try {
      // Get existing searches
      final searchesRef = collection.doc(userId).collection('searches');
      
      // Save new search with all fields
      final data = {
        'query': query.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Only add image_url if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        data['image_url'] = imageUrl;
      }

      await searchesRef.add(data);

      // Cleanup old searches
      final snapshots = await searchesRef
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshots.docs.length > maxSearches) {
        final toDelete = snapshots.docs.sublist(maxSearches);
        for (var doc in toDelete) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Error saving search: $e');
    }
  }

  Stream<QuerySnapshot> getRecentSearches() {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    return collection
        .doc(userId)
        .collection('searches')
        .orderBy('timestamp', descending: true)
        .limit(maxSearches)
        .snapshots();
  }

  Future<void> clearSearchHistory() async {
    if (userId.isEmpty) return;

    final snapshots = await collection
        .doc(userId)
        .collection('searches')
        .get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}
