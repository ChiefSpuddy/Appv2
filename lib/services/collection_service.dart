import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show Random, min, max;
import 'dart:convert';
import 'package:crypto/crypto.dart';  // Add this package to pubspec.yaml
import '../models/card_model.dart';
import '../models/custom_collection.dart';  // Add this import
import 'package:flutter/foundation.dart';
import '../models/collector_level.dart';  // Add this import at the top

class CollectionService {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final CollectionReference collection = FirebaseFirestore.instance.collection('cards');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _updatePriceHistory() async {
    try {
      final totalValue = await _calculateTotalValue();
      final now = DateTime.now();
      
      // Check if we already have an entry for today
      final todayStart = DateTime(now.year, now.month, now.day);
      final existingEntry = await collection
          .doc(userId)
          .collection('priceHistory')
          .where('timestamp', isGreaterThanOrEqualTo: todayStart)
          .get();

      if (existingEntry.docs.isEmpty) {
        await collection
            .doc(userId)
            .collection('priceHistory')
            .add({
              'totalValue': totalValue,
              'timestamp': FieldValue.serverTimestamp(),
            });
      } else {
        // Update the existing entry
        await existingEntry.docs.first.reference.update({
          'totalValue': totalValue,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
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
      
      final now = Timestamp.now();
      
      // First add the card
      await collection.doc(userId).collection('userCards').add({
        'id': card.id,
        'name': card.name,
        'imageUrl': card.imageUrl,
        'setName': card.setName,
        'rarity': card.rarity,
        'price': validPrice,
        'dateAdded': now,  // Use same timestamp for consistency
        'lastUpdated': now,
        'priceHistory': [{
          'price': validPrice,
          'timestamp': now,
        }],
      });
      
      // Update monthly stats
      await _updateMonthlyStats(validPrice ?? 0.0, true);
      
      // Update price history
      await _updatePriceHistory();
      
    } catch (e) {
      print('Error adding card: $e');
      throw Exception('Could not add card to collection');
    }
  }

  Future<void> removeCard(String docId) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the card's price before removing it
      final cardDoc = await collection.doc(userId).collection('userCards').doc(docId).get();
      final price = (cardDoc.data()?['price'] as num?)?.toDouble() ?? 0.0;

      // Remove the card
      await collection.doc(userId).collection('userCards').doc(docId).delete();

      // Update monthly stats with negative value
      await _updateMonthlyStats(price, false);

      // Update custom collections that contain this card
      await _removeCardFromCustomCollections(docId);

      // Update price history
      await _updatePriceHistory();
    } catch (e) {
      print('Error removing card: $e');
      throw Exception('Could not remove card from collection');
    }
  }

  Future<void> _updateMonthlyStats(double value, bool isAddition) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final monthlyStatsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('monthlyStats')
        .doc(monthKey);

    await monthlyStatsRef.set({
      'cardsAdded': FieldValue.increment(isAddition ? 1 : -1),
      'valueAdded': FieldValue.increment(isAddition ? value : -value),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _removeCardFromCustomCollections(String cardId) async {
    try {
      // Get all custom collections
      final collectionsSnapshot = await collection
          .doc(userId)
          .collection('customCollections')
          .get();

      // Update each collection that contains the card
      for (var collectionDoc in collectionsSnapshot.docs) {
        final cardIds = List<String>.from(collectionDoc.data()['cardIds'] ?? []);
        
        if (cardIds.contains(cardId)) {
          cardIds.remove(cardId);
          
          await collection
              .doc(userId)
              .collection('customCollections')
              .doc(collectionDoc.id)
              .update({
                'cardIds': cardIds,
              });

          // Update the collection's price history
          await _updateCollectionPriceHistory(collectionDoc.id);
        }
      }
    } catch (e) {
      print('Error updating custom collections: $e');
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
    return collection
        .doc(userId)
        .collection('userCards')
        .orderBy('price', descending: true) // Changed from dateAdded to price
        .snapshots();
  }

  Future<Map<String, dynamic>> getCollectionStats() async {
    try {
      final snapshot = await collection
          .doc(userId)
          .collection('userCards')
          .get();

      final cards = snapshot.docs;
      
      // Calculate collector score and milestones (keep existing code)
      final collectorScore = await calculateCollectorScore(cards);
      final nextMilestone = calculateNextMilestone(cards);
      final recentMilestones = await getRecentMilestones();

      // Calculate basic stats
      double totalValue = 0;
      final setDistribution = <String, int>{};
      final setValues = <String, double>{};  // Add this
      final rarityValues = <String, double>{};
      final rarityCount = <String, int>{};

      for (var doc in cards) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        totalValue += price;
        
        final setName = data['setName'] as String?;
        if (setName != null) {
          setDistribution[setName] = (setDistribution[setName] ?? 0) + 1;
          setValues[setName] = (setValues[setName] ?? 0) + price;  // Add this
        }

        final rarity = data['rarity'] as String?;
        if (rarity != null) {
          rarityValues[rarity] = (rarityValues[rarity] ?? 0) + price;
          rarityCount[rarity] = (rarityCount[rarity] ?? 0) + 1;
        }
      }

      // Calculate daily change
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Get start of today and yesterday
      final startOfToday = DateTime(today.year, today.month, today.day);
      final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final startOfTomorrow = startOfToday.add(const Duration(days: 1));
      
      final todaySnapshot = await collection
          .doc(userId)
          .collection('priceHistory')
          .where('timestamp', isGreaterThanOrEqualTo: startOfToday)
          .where('timestamp', isLessThan: startOfTomorrow)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      final yesterdaySnapshot = await collection
          .doc(userId)
          .collection('priceHistory')
          .where('timestamp', isGreaterThanOrEqualTo: startOfYesterday)
          .where('timestamp', isLessThan: startOfToday)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      double dailyChange = 0;
      double dailyChangePercent = 0;

      if (todaySnapshot.docs.isNotEmpty && yesterdaySnapshot.docs.isNotEmpty) {
        final todayValue = todaySnapshot.docs.first.get('totalValue') as double;
        final yesterdayValue = yesterdaySnapshot.docs.first.get('totalValue') as double;
        
        dailyChange = todayValue - yesterdayValue;
        if (yesterdayValue > 0) {
          dailyChangePercent = (dailyChange / yesterdayValue) * 100;
        }
      }

      // Calculate monthly stats properly
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final monthlyCardsSnapshot = await collection
          .doc(userId)
          .collection('userCards')
          .where('dateAdded', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      final monthlyValueSnapshot = await collection
          .doc(userId)
          .collection('priceHistory')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .orderBy('timestamp')
          .get();

      double monthStartValue = 0;
      double currentValue = totalValue;

      if (monthlyValueSnapshot.docs.isNotEmpty) {
        monthStartValue = monthlyValueSnapshot.docs.first.get('totalValue') as double;
      }

      final monthlyStats = {
        'cardsAdded': monthlyCardsSnapshot.docs.length,
        'valueAdded': currentValue - monthStartValue,
        'valueGrowth': currentValue - monthStartValue,
        'growthPercentage': monthStartValue > 0 
            ? ((currentValue - monthStartValue) / monthStartValue) * 100 
            : 0.0,
      };

      // Sort rarities by value to get the most valuable ones
      final sortedRarities = rarityCount.entries.toList()
        ..sort((a, b) => (rarityValues[b.key] ?? 0).compareTo(rarityValues[a.key] ?? 0));

      final topRarities = sortedRarities.take(3).map((e) => {
        'name': e.key,
        'count': e.value,
        'value': rarityValues[e.key],
      }).toList();

      return {
        'totalCards': cards.length,
        'totalValue': totalValue,
        'averageValue': cards.isEmpty ? 0 : totalValue / cards.length,
        'uniqueSets': setDistribution.length,
        'setDistribution': {
          ...setDistribution,
          'setValues': setValues,  // Add this
        },
        'rarityValues': rarityValues,
        'rarityCount': rarityCount,
        'topRarities': topRarities,
        'dailyChange': dailyChange,
        'dailyChangePercent': dailyChangePercent,
        'collectorScore': collectorScore,
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
        'rarityCount': {},
        'topRarities': [],
        'dailyChange': 0.0,
        'dailyChangePercent': 0.0,
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
    if (cardIds.isEmpty) return 0.0;  // Return 0 for empty collections

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
      return 0.0;  // Return 0 on error
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

  Stream<List<CustomCollection>> getCustomCollectionsStream() {
    if (userId.isEmpty) throw Exception('User not authenticated');
    
    return collection
        .doc(userId)
        .collection('customCollections')
        .snapshots()
        .asyncMap((snapshot) async {
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
                tags: List<String>.from(data['tags'] ?? []),
                shareCode: data['shareCode'],
                notes: List<Map<String, dynamic>>.from(data['notes'] ?? []),
                priceHistory: List<Map<String, dynamic>>.from(data['priceHistory'] ?? []),
              );
            }),
          );
          return collections;
        });
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

  Future<void> updateCollectionDetails(String collectionId, String name, String description) async {
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

    try {
      // First, verify the collection exists
      final collectionRef = collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId);

      final doc = await collectionRef.get();
      if (!doc.exists) {
        throw Exception('Collection not found');
      }

      // Delete the collection document
      await collectionRef.delete();
      
      // Navigate back after successful deletion
      return;
    } catch (e) {
      debugPrint('Error deleting collection: $e');
      throw Exception('Failed to delete collection');
    }
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

  Stream<List<TcgCard>> getCollectionCardsStream(String collectionId) {
    if (userId.isEmpty) throw Exception('User not authenticated');
    
    return collection
        .doc(userId)
        .collection('customCollections')
        .doc(collectionId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) return [];
          
          final cardIds = List<String>.from(doc.data()?['cardIds'] ?? []);
          if (cardIds.isEmpty) return [];

          final cards = await getCollectionCards(collectionId);
          return cards;
        });
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
      final collectionRef = collection
          .doc(userId)
          .collection('customCollections')
          .doc(collectionId);

      // Get current cardIds
      final doc = await collectionRef.get();
      if (!doc.exists) return;

      final cardIds = List<String>.from(doc.data()?['cardIds'] ?? []);
      if (cardIds.isEmpty) {
        // If collection is empty, just update with 0 value
        final historyEntry = {
          'value': 0.0,
          'timestamp': Timestamp.now(),  // Use Timestamp instead of serverTimestamp
        };

        await collectionRef.update({
          'priceHistory': FieldValue.arrayUnion([historyEntry]),
        });
        return;
      }

      final totalValue = await calculateCollectionValue(cardIds);
      final historyEntry = {
        'value': totalValue,
        'timestamp': Timestamp.now(),  // Use Timestamp instead of serverTimestamp
      };

      await collectionRef.update({
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

    // Enhanced XP calculations
    int totalXp = total;  // Start with existing total as base XP
    
    // Additional XP sources
    totalXp += await _calculateActivityXp();
    totalXp += await _calculateAchievementXp();
    totalXp += _calculateSetCompletionXp(cards);
    totalXp += _calculateRarityXp(cards);
    
    // Calculate level and progress
    final currentLevel = (totalXp / 100).floor();
    final currentXp = totalXp % 100;
    final requiredXp = CollectorLevel.calculateRequiredXp(currentLevel);
    
    // Calculate unlocked perks based on level
    final unlockedPerks = _calculateUnlockedPerks(currentLevel);
    
    // XP multipliers
    final multipliers = await _getXpMultipliers();

    return {
      'total': totalXp,
      'level': currentLevel,
      'currentXp': currentXp,
      'requiredXp': requiredXp,
      'progress': currentXp / requiredXp,
      'unlockedPerks': unlockedPerks,
      'multipliers': multipliers,
      ...bonuses,
    };
  }

  int _calculateRarityXp(List<DocumentSnapshot> cards) {
    int xp = 0;
    final rarityMultipliers = {
      'Common': 1,
      'Uncommon': 2,
      'Rare': 5,
      'Ultra Rare': 10,
      'Secret Rare': 20,
      'Trophy Card': 50,
    };

    for (var card in cards) {
      final data = card.data() as Map<String, dynamic>;
      final rarity = data['rarity'] as String?;
      if (rarity != null) {
        xp += rarityMultipliers[rarity] ?? 1;
      }
    }

    return xp;
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    final activities = await _firestore
        .collection('users')
        .doc(userId)
        .collection('activity')
        .where('timestamp', isGreaterThan: yesterday)
        .orderBy('timestamp', descending: true)
        .get();

    return activities.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _getCompletedAchievements() async {
    final achievements = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .where('completed', isEqualTo: true)
        .get();

    return achievements.docs.map((doc) => doc.data()).toList();
  }

  Map<String, double> _calculateSetCompletion(List<DocumentSnapshot> cards) {
    final setProgress = <String, double>{};
    final setCounts = <String, int>{};
    final setTotals = <String, int>{};

    // Count cards per set
    for (var card in cards) {
      final data = card.data() as Map<String, dynamic>;
      final setName = data['setName'] as String?;
      if (setName != null) {
        setCounts[setName] = (setCounts[setName] ?? 0) + 1;
        // This would ideally come from a separate collection containing set information
        setTotals[setName] = 100; // Placeholder: assume 100 cards per set
      }
    }

    // Calculate completion percentages
    setCounts.forEach((setName, count) {
      setProgress[setName] = count / (setTotals[setName] ?? 100);
    });

    return setProgress;
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    
    return doc.data() ?? {};
  }

  Future<double> _calculateStreakMultiplier() async {
    final streak = await _getActivityStreak();
    if (streak >= 30) return 2.0;     // 2x multiplier for 30+ day streak
    if (streak >= 14) return 1.5;     // 1.5x multiplier for 14+ day streak
    if (streak >= 7) return 1.25;     // 1.25x multiplier for 7+ day streak
    return 1.0;                       // Base multiplier
  }

  Future<int> _calculateActivityXp() async {
    final streak = await _getActivityStreak();
    int xp = 0;
    
    // Daily login rewards
    if (streak > 0) {
      xp += 10;  // Base daily XP
      if (streak >= 7) xp += 20;  // Weekly bonus
      if (streak >= 30) xp += 50;  // Monthly bonus
    }
    
    // Recent activity bonuses
    final recentActivity = await _getRecentActivity();
    xp += recentActivity.length * 5;  // 5 XP per activity
    
    return xp;
  }

  Future<int> _calculateAchievementXp() async {
    final achievements = await _getCompletedAchievements();
    return achievements.fold<int>(0, (sum, achievement) {
      switch (achievement['rarity']) {
        case 'common': return sum + 10;
        case 'rare': return sum + 25;
        case 'epic': return sum + 50;
        case 'legendary': return sum + 100;
        default: return sum;
      }
    });
  }

  int _calculateSetCompletionXp(List<DocumentSnapshot> cards) {
    final setProgress = _calculateSetCompletion(cards);
    int xp = 0;
    
    setProgress.forEach((setName, percentage) {
      if (percentage >= 1.0) xp += 100;  // Complete set bonus
      else if (percentage >= 0.75) xp += 50;  // 75% completion
      else if (percentage >= 0.5) xp += 25;  // 50% completion
    });
    
    return xp;
  }

  Map<String, String> _calculateUnlockedPerks(int level) {
    return {
      if (level >= 5) 'Custom Backgrounds': 'Unlock custom collection backgrounds',
      if (level >= 10) 'Price Alerts': 'Unlock price change alerts',
      if (level >= 15) 'Advanced Analytics': 'Unlock advanced analytics',
      if (level >= 20) 'Bulk Actions': 'Unlock bulk card management',
      if (level >= 25) 'Market Insights': 'Unlock market trend insights',
      // Add more perks as needed
    };
  }

  Future<Map<String, double>> _getXpMultipliers() async {
    // Fetch active multipliers from user data
    final userData = await _getUserData();
    return {
      'weekend_bonus': 1.5,  // Weekend bonus multiplier
      'event_bonus': userData['eventMultiplier'] ?? 1.0,  // Special event multiplier
      'streak_bonus': await _calculateStreakMultiplier(),
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

  Future<bool> cardExists(String cardId) async {
    if (userId.isEmpty) return false;

    try {
      final querySnapshot = await collection
          .doc(userId)
          .collection('userCards')
          .where('id', isEqualTo: cardId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if card exists: $e');
      return false;
    }
  }

  Future<void> updateCollectionField(String collectionId, String userId, Map<String, dynamic> data) async {
    await _firestore.collection('custom_collections')
        .doc(collectionId)
        .update(data);
  }

  Future<void> removeCardFromCollection(String collectionId, String cardId, String userId) async {
    await _firestore.collection('custom_collections')
        .doc(collectionId)
        .update({
          'cardIds': FieldValue.arrayRemove([cardId])
        });
  }
}
