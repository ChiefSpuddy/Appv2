import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_background.dart';

class BackgroundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<List<CollectionBackground>> getAvailableBackgrounds(String userId) {
    return _firestore.collection('backgrounds')
        .snapshots()
        .asyncMap((snapshot) async {
          // Get user's unlocked backgrounds
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          
          final unlockedBackgrounds = List<String>.from(
            userDoc.data()?['unlockedBackgrounds'] ?? []
          );

          return snapshot.docs.map((doc) {
            final data = doc.data();
            return CollectionBackground.fromMap(
              data,
              isUnlocked: unlockedBackgrounds.contains(doc.id),
            );
          }).toList();
        });
  }

  Future<void> setCollectionBackground(
    String userId,
    String collectionId,
    String backgroundId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('customCollections')
        .doc(collectionId)
        .update({
          'backgroundId': backgroundId,
        });
  }

  Future<void> initializeDefaultBackgrounds() async {
    final backgrounds = [
      {
        'id': 'gradient_blue',
        'name': 'Blue Gradient',
        'previewUrl': 'assets/backgrounds/gradient_blue.png',
        'style': {
          'gradient': {
            'colors': ['#1E88E5', '#1565C0'],
            'begin': 'topLeft',
            'end': 'bottomRight',
          }
        },
        'isPremium': false,
      },
      {
        'id': 'gradient_purple',
        'name': 'Purple Dream',
        'previewUrl': 'assets/backgrounds/gradient_purple.png',
        'style': {
          'gradient': {
            'colors': ['#9C27B0', '#6A1B9A'],
            'begin': 'topLeft',
            'end': 'bottomRight',
          }
        },
        'isPremium': false,
      },
      // Add more background presets
    ];

    final batch = _firestore.batch();
    for (var bg in backgrounds) {
      final doc = _firestore.collection('backgrounds').doc(bg['id'] as String);
      batch.set(doc, bg, SetOptions(merge: true));
    }
    
    await batch.commit();
  }
}
