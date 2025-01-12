import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show Random, min, max;
import 'dart:convert';
import 'package:crypto/crypto.dart';  // Add this package to pubspec.yaml
import '../models/card_model.dart';
import '../models/custom_collection.dart';  // Add this import
import 'package:flutter/foundation.dart';

class CollectionService {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final CollectionReference collection = FirebaseFirestore.instance.collection('cards');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _updatePriceHistory() async {
    try {
      final totalValue = await _calculateTotalValue();
      await collection.doc(userId).collection('priceHistory').add({
        'totalValue': totalValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating price history: $e');
    }
  }

  Future<void> addCard(TcgCard card) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    
    try {
      final double? validPrice = card.price != null ? 
          double.parse(card.price!.toStringAsFixed(2)) : null;
          
      // Use regular timestamp for array items
      final now = Timestamp.now();
      final priceHistoryEntry = {
        'price': validPrice,
        'timestamp': now,  // Regular timestamp instead of FieldValue
      };

      await collection.doc(userId).collection('userCards').add({
        'id': card.id,
        'name': card.name,
        'imageUrl': card.imageUrl,
        'setName': card.setName,
        'rarity': card.rarity,
        'price': validPrice,
        'dateAdded': FieldValue.serverTimestamp(),  // This is fine as it's not in an array
        'lastUpdated': FieldValue.serverTimestamp(),
        'priceHistory': [priceHistoryEntry],
      });
      
      await _updatePriceHistory();
    } catch (e) {
      print('Error adding card: $e');
      throw Exception('Could not add card to collection');
    }
  }

  Future<void> _schedulePriceUpdate(String docId, String cardId) async {
    // Update price every 24 hours
    Future.delayed(const Duration(hours: 24), () async {
      try {
        // Fetch current market price (you'll need to implement this)
        final newPrice = await _fetchCurrentPrice(cardId);
        if (newPrice != null) {
          final docRef = collection.doc(userId).collection('userCards').doc(docId);
          final doc = await docRef.get();
          
          if (doc.exists) {
            final currentData = doc.data() as Map<String, dynamic>;
            final List<dynamic> priceHistory = List.from(currentData['priceHistory'] ?? []);
            
            // Add new price to history with regular timestamp
            priceHistory.add({
              'price': newPrice,
              'timestamp': Timestamp.now(),  // Regular timestamp instead of FieldValue
            });

            // Update document
            await docRef.update({
              'price': newPrice,
              'lastUpdated': FieldValue.serverTimestamp(),
              'priceHistory': priceHistory,
            });

            // Schedule next update
            _schedulePriceUpdate(docId, cardId);
          }
        }
      } catch (e) {
        print('Error updating price: $e');
      }
    });
  }

  Future<double?> _fetchCurrentPrice(String cardId) async {
    try {
      final docRef = collection.doc(userId).collection('userCards');
      final doc = await docRef.where('id', isEqualTo: cardId).get();
      
      if (doc.docs.isNotEmpty) {
        final currentPrice = doc.docs.first.get('price') as double?;
        if (currentPrice != null) {
          // Simulate price change (-5% to +5%)
          final random = Random();
          final change = (currentPrice * (random.nextDouble() * 0.1 - 0.05));
          return double.parse((currentPrice + change).toStringAsFixed(2));
        }
      }
    } catch (e) {
      print('Error fetching current price: $e');
    }
    return null;
  }

  Future<double> _calculateTotalValue() async {
    final snapshot = await collection.doc(userId).collection('userCards').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['price'] != null) {
        total += (data['price'] as num).toDouble();
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  Future<List<Map<String, dynamic>>> getPriceHistory({int months = 1}) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final DateTime cutoff = DateTime.now().subtract(Duration(days: months * 30));
      
      final snapshot = await collection
          .doc(userId)
          .collection('priceHistory')
          .orderBy('timestamp', descending: false)
          .where('timestamp', isGreaterThanOrEqualTo: cutoff)
          .get();

      if (snapshot.docs.isEmpty) {
        final currentValue = await _calculateTotalValue();
        await _updatePriceHistory();
        return [
          {
            'value': currentValue,
            'timestamp': DateTime.now(),
          }
        ];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'value': data['totalValue'] as double,
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching price history: $e');
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCards() {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    return collection.doc(userId).collection('userCards').orderBy('dateAdded', descending: true).snapshots();
  }

  Future<void> removeCard(String docId) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    await collection.doc(userId).collection('userCards').doc(docId).delete();
    // Update price history after removing card
    await _updatePriceHistory();
  }

  Future<Map<String, dynamic>> getCollectionStats() async {
    try {
      // Update collection path to use cards/{userId}/userCards
      final snapshot = await collection
          .doc(userId)
          .collection('userCards')
          .get();

      final cards = snapshot.docs;
      
      // Calculate collector score
      final collectorScore = await calculateCollectorScore(cards);
      final nextMilestone = calculateNextMilestone(cards);
      final recentMilestones = await getRecentMilestones();

      // Calculate other stats
      double totalValue = 0;
      final setDistribution = <String, int>{};
      final rarityValues = <String, double>{};

      for (var doc in cards) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        totalValue += price;
        
        final setName = data['setName'] as String?;
        if (setName != null) {
          setDistribution[setName] = (setDistribution[setName] ?? 0) + 1;
        }

        final rarity = data['rarity'] as String?;
        if (rarity != null) {
          rarityValues[rarity] = (rarityValues[rarity] ?? 0) + price;
        }
      }

      // Add monthly stats calculation
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      // Get all card additions this month
      final monthlyAdditions = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cards')
          .where('addedAt', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      // Calculate monthly stats
      final monthlyStats = {
        'cardsAdded': monthlyAdditions.docs.length,
        'valueAdded': monthlyAdditions.docs
            .map((doc) => doc.data()['price'] as double? ?? 0.0)
            .fold<double>(0, (sum, price) => sum + price),
        'growthPercentage': 0.0,
        'valueGrowth': 0.0,
      };

      // Calculate growth percentage if we have previous month's data
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final previousMonthSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('monthlyStats')
          .doc(lastMonth.toString().substring(0, 7))
          .get();

      if (previousMonthSnapshot.exists) {
        final previousValue = previousMonthSnapshot.data()?['totalValue'] as double? ?? 0.0;
        if (previousValue > 0) {
          final currentValue = monthlyStats['valueAdded'] as double;
          monthlyStats['valueGrowth'] = currentValue - previousValue;
          monthlyStats['growthPercentage'] = ((currentValue - previousValue) / previousValue) * 100;
        }
      }

      // Store current month's stats
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('monthlyStats')
          .doc(now.toString().substring(0, 7))
          .set({
        'totalValue': totalValue,
        'cardCount': cards.length,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return {
        'totalCards': cards.length,
        'totalValue': totalValue,
        'averageValue': cards.isEmpty ? 0 : totalValue / cards.length,
        'uniqueSets': setDistribution.length,
        'setDistribution': setDistribution,
        'rarityValues': rarityValues,
        'collectorScore': {
          'total': collectorScore['total'],
          'level': collectorScore['level'],
          'progress': collectorScore['progress'],
          'nextLevelPoints': collectorScore['nextLevelPoints'],
          'rarityBonus': collectorScore['rarityBonus'],
          'completionBonus': collectorScore['completionBonus'],
          'valueBonus': collectorScore['valueBonus'],
          'firstEditionBonus': collectorScore['firstEditionBonus'],
          'diversityBonus': collectorScore['diversityBonus'],
          'gradeBonus': collectorScore['gradeBonus'],
          'streakBonus': collectorScore['streakBonus'],
        },
        'monthlyStats': monthlyStats,
        'nextMilestone': nextMilestone,
        'recentMilestones': recentMilestones,
      };
    } catch (e) {
      debugPrint('Error getting collection stats: $e');
      return {
        'totalCards': 0,
        'totalValue': 0.0,
        'averageValue': 0.0,
        'uniqueSets': 0,
        'setDistribution': {},
        'rarityValues': {},
        'collectorScore': {
          'total': 0,
          'level': 0,
          'progress': 0.0,
          'nextLevelPoints': 100,
        },
        'monthlyStats': {
          'cardsAdded': 0,
          'valueAdded': 0.0,
          'valueGrowth': 0.0,
          'growthPercentage': 0.0,
        },
      };
    }
  }

  Future<double> _getPreviousMonthValue() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    
    try {
      final snapshot = await collection
          .doc(userId)
          .collection('priceHistory')
          .where('timestamp', isLessThan: lastMonth)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('totalValue') as double;
      }
    } catch (e) {
      print('Error getting previous month value: $e');
    }
    return 0.0;
  }

  Future<Map<String, dynamic>> _getCompletionStats() async {
    // This would require knowledge of total cards in each set
    // For now, return placeholder data
    return {
      'totalSetsCompleted': 0,
      'highestCompletionSet': '',
      'completionPercentage': 0.0,
    };
  }

  Future<List<TcgCard>> searchCollection(String query) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    final snapshot = await collection.doc(userId).collection('userCards')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TcgCard(
        id: data['id'],
        name: data['name'],
        imageUrl: data['imageUrl'],
        setName: data['setName'],
        rarity: data['rarity'],
        price: data['price']?.toDouble(),
      );
    }).toList();
  }

  Future<List<TcgCard>> getSortedCards(String sortBy) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    late QuerySnapshot snapshot;
    
    switch (sortBy) {
      case 'name':
        snapshot = await collection.doc(userId).collection('userCards').orderBy('name').get();
        break;
      case 'price':
        snapshot = await collection.doc(userId).collection('userCards').orderBy('price', descending: true).get();
        break;
      case 'date':
        snapshot = await collection.doc(userId).collection('userCards').orderBy('dateAdded', descending: true).get();
        break;
      default:
        snapshot = await collection.doc(userId).collection('userCards').get();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TcgCard(
        id: data['id'],
        name: data['name'],
        imageUrl: data['imageUrl'],
        setName: data['setName'],
        rarity: data['rarity'],
        price: data['price']?.toDouble(),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getBiggestMovers({
    Duration period = const Duration(days: 7),
  }) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final snapshot = await collection
          .doc(userId)
          .collection('userCards')
          .get();

      final now = DateTime.now();
      final periodStart = now.subtract(period);
      List<Map<String, dynamic>> movers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final priceHistory = List<Map<String, dynamic>>.from(data['priceHistory'] ?? []);
        
        if (priceHistory.length < 2) continue;

        // Get current and previous prices within the period
        final currentPrice = data['price'] as double?;
        final historicalPrices = priceHistory
            .where((ph) => (ph['timestamp'] as Timestamp).toDate().isAfter(periodStart))
            .map((ph) => ph['price'] as double?);

        if (currentPrice == null || historicalPrices.isEmpty) continue;

        final oldestPrice = historicalPrices.first;
        if (oldestPrice == null) continue;

        final priceChange = currentPrice - oldestPrice;
        final percentageChange = (priceChange / oldestPrice) * 100;

        movers.add({
          'id': data['id'],
          'name': data['name'],
          'imageUrl': data['imageUrl'],
          'currentPrice': currentPrice,
          'oldPrice': oldestPrice,
          'priceChange': priceChange,
          'percentageChange': percentageChange,
        });
      }

      // Sort by absolute percentage change
      movers.sort((a, b) => b['percentageChange'].abs().compareTo(a['percentageChange'].abs()));
      
      // Return top 5 movers
      return movers.take(5).toList();
    } catch (e) {
      print('Error getting biggest movers: $e');
      return [];
    }
  }

  Future<double> calculateCollectionValue(List<String> cardIds) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final cards = await collection
          .doc(userId)
          .collection('userCards')
          .where(FieldPath.documentId, whereIn: cardIds)
          .get();

      double total = 0;
      for (var doc in cards.docs) {
        final data = doc.data();
        if (data['price'] != null) {
          total += (data['price'] as num).toDouble();
        }
      }
      return double.parse(total.toStringAsFixed(2));
    } catch (e) {
      print('Error calculating collection value: $e');
      return 0.0;
    }
  }

  Future<List<CustomCollection>> getCustomCollections() async {
    if (userId.isEmpty) throw Exception('User not authenticated');
    
    try {
      final snapshot = await collection
          .doc(userId)
          .collection('customCollections')
          .orderBy('createdAt', descending: true)
          .get();

      final collections = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          final cardIds = List<String>.from(data['cardIds'] ?? []);
          final totalValue = await calculateCollectionValue(cardIds);
          
          return CustomCollection(
            id: doc.id,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            cardIds: cardIds,
            totalValue: totalValue,
          );
        }),
      );

      return collections;
    } catch (e) {
      print('Error getting custom collections: $e');
      rethrow;
    }
  }

  Future<CustomCollection> createCustomCollection(String name, String description) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final docRef = await collection
          .doc(userId)
          .collection('customCollections')
          .add({
            'name': name,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'cardIds': [],
          });

      return CustomCollection(
        id: docRef.id,
        name: name,
        description: description,
        createdAt: DateTime.now(),
        cardIds: [],
      );
    } catch (e) {
      print('Error creating custom collection: $e');
      rethrow;
    }
  }

  Future<void> addCardsToCollection(String collectionId, List<String> cardIds) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    await collection
        .doc(userId)
        .collection('customCollections')
        .doc(collectionId)
        .update({
          'cardIds': FieldValue.arrayUnion(cardIds),
        });
  }

  Future<void> removeCardsFromCollection(String collectionId, List<String> cardIds) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final collectionRef = collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId);

      // Get current cardIds
      final doc = await collectionRef.get();
      if (!doc.exists) throw Exception('Collection not found');

      final currentCardIds = List<String>.from(doc.data()?['cardIds'] ?? []);
      currentCardIds.removeWhere((id) => cardIds.contains(id));

      // Update collection with new cardIds
      await collectionRef.update({
        'cardIds': currentCardIds,
      });

      // Update collection price history
      await _updateCollectionPriceHistory(collectionId);
    } catch (e) {
      print('Error removing cards from collection: $e');
      rethrow;
    }
  }

  Future<void> updateCollection(String collectionId, String name, String description) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    await collection
        .doc(userId)
        .collection('customCollections')
        .doc(collectionId)
        .update({
          'name': name,
          'description': description,
        });
  }

  Future<void> deleteCollection(String collectionId) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    await collection
        .doc(userId)
        .collection('customCollections')
        .doc(collectionId)
        .delete();
  }

  Future<List<TcgCard>> getCollectionCards(
    String collectionId, {
    String? sortBy,
    String? filterBy,
  }) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final collectionDoc = await this.collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId)
          .get();

      if (!collectionDoc.exists) {
        throw Exception('Collection not found');
      }

      final cardIds = List<String>.from(collectionDoc.data()?['cardIds'] ?? []);
      if (cardIds.isEmpty) return [];

      // Split cardIds into chunks of 10 due to Firestore "in" query limitation
      final chunks = <List<String>>[];
      for (var i = 0; i < cardIds.length; i += 10) {
        chunks.add(cardIds.sublist(i, min(i + 10, cardIds.length)));
      }

      final allCards = <TcgCard>[];
      
      // Query each chunk
      for (final chunk in chunks) {
        Query<Map<String, dynamic>> query = this.collection
            .doc(userId)
            .collection('userCards')
            .where(FieldPath.documentId, whereIn: chunk);

        if (sortBy != null) {
          switch (sortBy) {
            case 'name':
              query = query.orderBy('name');
              break;
            case 'price':
              query = query.orderBy('price', descending: true);
              break;
            case 'date':
              query = query.orderBy('dateAdded', descending: true);
              break;
          }
        }

        final snapshot = await query.get();
        final cards = snapshot.docs.map((doc) {
          final data = doc.data();
          return TcgCard(
            id: data['id'] as String,
            name: data['name'] as String,
            imageUrl: data['imageUrl'] as String,
            setName: data['setName'] as String,
            rarity: data['rarity'] as String,
            price: data['price'] as double?,
          );
        }).toList();

        allCards.addAll(cards);
      }

      // Sort the complete list if needed
      if (sortBy != null) {
        switch (sortBy) {
          case 'name':
            allCards.sort((a, b) => a.name.compareTo(b.name));
            break;
          case 'price':
            allCards.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
            break;
        }
      }

      return allCards;
    } catch (e) {
      print('Error getting collection cards: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> exportCollection(String collectionId) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final collection = await this.collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId)
          .get();

      if (!collection.exists) {
        throw Exception('Collection not found');
      }

      final cards = await getCollectionCards(collectionId);
      final data = collection.data()!;

      return {
        'name': data['name'],
        'description': data['description'],
        'createdAt': data['createdAt'],
        'totalValue': cards.fold<double>(
          0, 
          (sum, card) => sum + (card.price ?? 0),
        ),
        'cards': cards.map((card) => {
          'name': card.name,
          'setName': card.setName,
          'rarity': card.rarity,
          'price': card.price,
        }).toList(),
      };
    } catch (e) {
      print('Error exporting collection: $e');
      rethrow;
    }
  }

  Future<String> shareCollection(String collectionId) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    try {
      final collection = await this.collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId)
          .get();

      if (!collection.exists) throw Exception('Collection not found');

      // Generate unique share code
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final hash = sha256.convert(utf8.encode('$userId$collectionId$timestamp')).toString();
      final shareCode = hash.substring(0, 8);

      // Update collection with share code
      await this.collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId)
          .update({'shareCode': shareCode});

      return shareCode;
    } catch (e) {
      print('Error sharing collection: $e');
      rethrow;
    }
  }

  Future<void> addNoteToCollection(
    String collectionId, 
    String note, {
    List<String>? cardIds,
  }) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    final noteData = {
      'text': note,
      'timestamp': FieldValue.serverTimestamp(),
      'cardIds': cardIds ?? [],
    };

    await collection
        .doc(userId)
        .collection('customCollections')
        .doc(collectionId)
        .update({
          'notes': FieldValue.arrayUnion([noteData]),
        });
  }

  Future<void> updateCollectionTags(
    String collectionId, 
    List<String> tags,
  ) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    await collection
        .doc(userId)
        .collection('customCollections')
        .doc(collectionId)
        .update({'tags': tags});
  }

  Future<void> performBulkOperation({
    required String collectionId,
    required List<String> cardIds,
    required String operation,
  }) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    switch (operation) {
      case 'add':
        await addCardsToCollection(collectionId, cardIds);
        break;
      case 'remove':
        await removeCardsFromCollection(collectionId, cardIds);
        break;
      case 'move':
        // TODO: Implement move operation
        break;
    }

    // Update price history after bulk operations
    await _updateCollectionPriceHistory(collectionId);
  }

  Future<void> _updateCollectionPriceHistory(String collectionId) async {
    try {
      final totalValue = await calculateCollectionValue(
        (await getCollectionCards(collectionId)).map((c) => c.id).toList(),
      );

      final historyEntry = {
        'value': totalValue,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId)
          .update({
            'priceHistory': FieldValue.arrayUnion([historyEntry]),
          });
    } catch (e) {
      print('Error updating collection price history: $e');
    }
  }

  Future<Map<String, dynamic>> calculateCollectorScore(List<DocumentSnapshot> cards) async {
    final Map<String, dynamic> bonuses = {
      'rarityBonus': 0,
      'completionBonus': 0,
      'valueBonus': 0,
      'firstEditionBonus': 0,
      'diversityBonus': 0,
      'gradeBonus': 0,
      'streakBonus': 0,
    };

    // Rarity points with enhanced values
    final rarityPoints = {
      'Common': 1,
      'Uncommon': 3,
      'Rare': 7,
      'Ultra Rare': 15,
      'Secret Rare': 25,
      'Trophy Card': 50,
    };

    // Track unique properties for diversity bonus
    final uniqueSets = <String>{};
    final uniqueTypes = <String>{};
    int firstEditionCount = 0;
    double totalValue = 0;
    
    // Calculate set completion percentages
    final setCards = <String, Set<String>>{};
    final setTotals = <String, int>{};

    for (var card in cards) {
      final data = card.data() as Map<String, dynamic>;
      
      // Rarity Bonus
      final rarity = data['rarity'] as String?;
      if (rarity != null) {
        bonuses['rarityBonus'] += rarityPoints[rarity] ?? 1;
      }

      // First Edition Bonus
      if (data['isFirstEdition'] == true) {
        firstEditionCount++;
      }

      // Set & Type Diversity
      if (data['setName'] != null) uniqueSets.add(data['setName']);
      if (data['type'] != null) uniqueTypes.add(data['type']);

      // Grade Bonus
      final grade = data['grade'] as num?;
      if (grade != null) {
        bonuses['gradeBonus'] += (grade / 10).round() * 5;
      }

      // Track set completion
      final setName = data['setName'] as String?;
      if (setName != null) {
        setCards.putIfAbsent(setName, () => {}).add(card.id);
        setTotals[setName] = (setTotals[setName] ?? 0) + 1;
      }

      // Value tracking
      totalValue += (data['price'] as num?)?.toDouble() ?? 0;
    }

    // Calculate Set Completion Bonus
    for (var set in setCards.entries) {
      final completion = set.value.length / (setTotals[set.key] ?? 1);
      if (completion >= 0.9) { // 90% or more completion
        bonuses['completionBonus'] += 50;
      } else if (completion >= 0.7) { // 70% or more completion
        bonuses['completionBonus'] += 25;
      } else if (completion >= 0.5) { // 50% or more completion
        bonuses['completionBonus'] += 10;
      }
    }

    // Diversity Bonus
    bonuses['diversityBonus'] = (uniqueSets.length * 5) + (uniqueTypes.length * 3);

    // First Edition Bonus
    bonuses['firstEditionBonus'] = firstEditionCount * 10;

    // Value Bonus (1 point per €10, with diminishing returns)
    bonuses['valueBonus'] = (totalValue / 10 * 0.8).round();

    // Activity Streak Bonus (if implemented)
    final streak = await _getActivityStreak();
    bonuses['streakBonus'] = streak * 5;

    // Calculate total score with weights
    final total = bonuses.values.fold<int>(0, (sum, bonus) => sum + (bonus as int));

    // Calculate levels
    final level = (total / 100).floor();
    final nextLevelPoints = (level + 1) * 100;
    final progress = (total % 100) / 100;

    return {
      'total': total,
      'level': level,
      'nextLevelPoints': nextLevelPoints,
      'progress': progress,
      ...bonuses,
    };
  }

  Future<int> _getActivityStreak() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final activityDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activity')
          .doc('streak')
          .get();

      return activityDoc.data()?['currentStreak'] ?? 0;
    } catch (e) {
      debugPrint('Error getting activity streak: $e');
      return 0;
    }
  }

  Map<String, dynamic> calculateNextMilestone(List<DocumentSnapshot> cards) {
    final milestones = [
      {'target': 10, 'description': 'Collect 10 cards'},
      {'target': 50, 'description': 'Grow your collection to 50 cards'},
      {'target': 100, 'description': 'Reach 100 cards'},
      {'target': 250, 'description': 'Build a collection of 250 cards'},
      {'target': 500, 'description': 'Achieve 500 cards milestone'},
      {'target': 1000, 'description': 'Join the 1000 cards club'},
    ];

    final cardCount = cards.length;
    
    for (var milestone in milestones) {
      final target = milestone['target'] as int;
      if (cardCount < target) {
        return {
          'target': target,
          'description': milestone['description'],
          'progress': cardCount / target,
        };
      }
    }

    return {
      'target': cardCount + 100,
      'description': 'Collect ${cardCount + 100} cards',
      'progress': 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentMilestones() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('milestones')
          .orderBy('achievedAt', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'date': (data['achievedAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting milestones: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getMonthlyStats() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime monthStart = DateTime(now.year, now.month, 1);
      final DateTime lastMonthStart = DateTime(now.year, now.month - 1, 1);
      
      // Get cards from userCards collection
      final monthlyCardsSnapshot = await collection
          .doc(userId)
          .collection('userCards')
          .where('addedAt', isGreaterThanOrEqualTo: monthStart)
          .get();

      final lastMonthCardsSnapshot = await collection
          .doc(userId)
          .collection('userCards')
          .where('addedAt', isGreaterThanOrEqualTo: lastMonthStart)
          .where('addedAt', isLessThan: monthStart)
          .get();

      // Calculate monthly stats
      final int cardsAdded = monthlyCardsSnapshot.docs.length;
      final double valueAdded = monthlyCardsSnapshot.docs.fold(
        0.0,
        (sum, card) => sum + (card.data()['price'] as num? ?? 0).toDouble(),
      );

      // Calculate growth percentage
      final double lastMonthValue = lastMonthCardsSnapshot.docs.fold(
        0.0,
        (sum, card) => sum + (card.data()['price'] as num? ?? 0).toDouble(),
      );
      
      final double growthPercentage = lastMonthValue > 0
          ? ((valueAdded - lastMonthValue) / lastMonthValue * 100)
          : (valueAdded > 0 ? 100 : 0);

      return {
        'cardsAdded': cardsAdded,
        'valueAdded': valueAdded,
        'valueGrowth': valueAdded - lastMonthValue,
        'growthPercentage': growthPercentage,
        'lastMonthValue': lastMonthValue,
      };
    } catch (e) {
      debugPrint('Error getting monthly stats: $e');
      return {
        'cardsAdded': 0,
        'valueAdded': 0.0,
        'valueGrowth': 0.0,
        'growthPercentage': 0.0,
        'lastMonthValue': 0.0,
      };
    }
  }
}
