import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show min, max;
import '../models/custom_collection.dart';
import '../services/collection_service.dart';
import '../widgets/card_item.dart';
import '../models/card_model.dart';
import '../dialogs/rename_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomCollectionDetailScreen extends StatefulWidget {
  final CustomCollection collection;

  const CustomCollectionDetailScreen({
    super.key,
    required this.collection,
  });

  @override
  State<CustomCollectionDetailScreen> createState() => _CustomCollectionDetailScreenState();
}

class _CustomCollectionDetailScreenState extends State<CustomCollectionDetailScreen> {
  late CustomCollection collection;

  @override
  void initState() {
    super.initState();
    collection = widget.collection;
  }

  @override
  Widget build(BuildContext context) {
    final service = CollectionService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showRenameDialog(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection Header
          _buildCollectionHeader(collection),
          // Cards Grid
          Expanded(
            child: StreamBuilder<List<TcgCard>>(
              stream: service.getCollectionCardsStream(collection.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cards = snapshot.data ?? [];
                if (cards.isEmpty) {
                  return const Center(
                    child: Text('No cards in this collection'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width ~/ 120, // Responsive grid
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Stack(
                      children: [
                        CardItem(
                          card: card,
                          docId: collection.id,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                            onPressed: () => _removeCard(context, service, card),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: collection.name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                setState(() {
                  collection = collection.copyWith(name: value);
                });
              },
            ),
            TextFormField(
              initialValue: collection.description,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) {
                setState(() {
                  collection = collection.copyWith(description: value);
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () => Navigator.pop(context, {
              'name': collection.name,
              'description': collection.description,
            }),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await CollectionService().updateCollectionDetails(
          collection.id,
          result['name']!,
          result['description']!,
        );
        
        setState(() {
          collection = collection.copyWith(
            name: result['name']!,
            description: result['description']!,
          );
        });
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update collection')),
          );
        }
      }
    }
  }

  void _showBackgroundPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.stars,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Custom Backgrounds',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Coming Soon!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reach Collector Level 5 to unlock custom backgrounds for your collections',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getCollectionStats() async {
    final service = CollectionService();
    final cards = await service.getCollectionCards(collection.id);
    
    // Only calculate unique sets
    final sets = cards.map((card) => card.setName).where((set) => set.isNotEmpty).toSet();
    
    // Calculate 24h change
    final priceHistory = collection.priceHistory;
    double growth24h = 0;
    double growthPercentage = 0;
    
    if (priceHistory.length >= 2) {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final latestPrice = collection.totalValue ?? 0;
      final previousPrices = priceHistory
          .where((entry) => (entry['timestamp'] as Timestamp)
              .toDate()
              .isBefore(yesterday))
          .map((e) => e['value'] as double);
          
      if (previousPrices.isNotEmpty) {
        final previousPrice = previousPrices.last;
        growth24h = latestPrice - previousPrice;
        growthPercentage = previousPrice > 0 ? (growth24h / previousPrice) * 100 : 0;
      }
    }

    return {
      'uniqueSets': sets.length,
      'growth24h': growth24h,
      'growthPercentage': growthPercentage,
    };
  }

  Widget _buildCollectionHeader(CustomCollection collection) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCollectionStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'uniqueSets': 0,
          'growth24h': 0.0,
          'growthPercentage': 0.0,
        };

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description section
                if (collection.description.isNotEmpty) ...[
                  Text(
                    collection.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Divider(),
                ],
                
                // Value and 24h change section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Value',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '€${collection.totalValue?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 24h Change indicator
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stats['growth24h'] >= 0 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '24h Change',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                stats['growth24h'] >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                                color: stats['growth24h'] >= 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '€${stats['growth24h'].abs().toStringAsFixed(2)}\n${stats['growthPercentage'].abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: stats['growth24h'] >= 0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Collection stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      'Cards',
                      collection.cardIds.length.toString(),
                      Icons.style,
                    ),
                    _buildStatItem(
                      'Sets',
                      stats['uniqueSets'].toString(),
                      Icons.category,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChart(List<Map<String, dynamic>> priceHistory) {
    if (priceHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = priceHistory.map((entry) {
      final timestamp = entry['timestamp'] as Timestamp;
      final value = entry['value'] as double;
      return FlSpot(
        timestamp.toDate().millisecondsSinceEpoch.toDouble(),
        value,
      );
    }).toList();

    // Calculate min and max for Y axis
    final minY = spots.map((s) => s.y).reduce(min);
    final maxY = spots.map((s) => s.y).reduce(max);
    final padding = (maxY - minY) * 0.1;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 86400000 * 2, // Show date every 2 days
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: spots.first.x,
          maxX: spots.last.x,
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  int _calculateUniqueSets(CustomCollection collection) {
    // Implementation
    return 0;
  }

  Future<void> _removeCard(BuildContext context, CollectionService service, TcgCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Are you sure you want to remove ${card.name} from this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        print('Removing card ${card.id} from collection ${collection.id}'); // Debug log
        await service.removeCardsFromCollection(collection.id, [card.id]);
        
        // Update local state
        setState(() {
          collection = collection.copyWith(
            cardIds: List.from(collection.cardIds)..remove(card.id),
          );
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed ${card.name} from collection')),
          );
        }
      } catch (e) {
        print('Error removing card: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove card from collection'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
