import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/custom_collection.dart';
import '../services/collection_service.dart';
import '../widgets/card_item.dart';
import '../models/card_model.dart';
import '../dialogs/rename_dialog.dart';  // Add this import
import 'package:firebase_auth/firebase_auth.dart';  // Add this import

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
  late CustomCollection _collection;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
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
              initialValue: _collection.name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                setState(() {
                  _collection = _collection.copyWith(name: value);
                });
              },
            ),
            TextFormField(
              initialValue: _collection.description,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) {
                setState(() {
                  _collection = _collection.copyWith(description: value);
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
              'name': _collection.name,
              'description': _collection.description,
            }),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await CollectionService().updateCollectionDetails(
          _collection.id,
          result['name']!,
          result['description']!,
        );
        
        setState(() {
          _collection = _collection.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final service = CollectionService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_collection.name),
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
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_collection.description.isNotEmpty) ...[
                    Text(
                      _collection.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Divider(),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_collection.cardIds.length} cards',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_collection.totalValue != null)
                        Text(
                          '€${_collection.totalValue!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Cards Grid
          Expanded(
            child: StreamBuilder<List<TcgCard>>(
              stream: service.getCollectionCardsStream(_collection.id),
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
                          docId: _collection.id,
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

  Future<void> _removeCard(BuildContext context, CollectionService service, TcgCard card) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: const Text('Are you sure you want to remove this card from the collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.removeCardFromCollection(_collection.id, card.id, userId);
    }
  }
}
