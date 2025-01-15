import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/custom_collection.dart';
import '../services/collection_service.dart';

class CollectionSelectionSheet extends StatelessWidget {
  final TcgCard card;
  final List<CustomCollection> existingCollections;

  const CollectionSelectionSheet({
    super.key,
    required this.card,
    required this.existingCollections,
  });

  Future<void> _createNewCollection(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Collection'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter collection name',
                ),
                validator: (value) => 
                  value?.isEmpty == true ? 'Please enter a name' : null,
                onSaved: (value) => name = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add a description',
                ),
                onSaved: (value) => description = value ?? '',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                formKey.currentState?.save();
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final service = CollectionService();
        final collection = await service.createCustomCollection(name, description);
        await service.addCardsToCollection(collection.id, [card.id]);

        if (context.mounted) {
          Navigator.pop(context); // Close the bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added to new collection "$name"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create collection'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addToExistingCollection(
    BuildContext context,
    CustomCollection collection,
  ) async {
    try {
      final service = CollectionService();
      await service.addCardsToCollection(collection.id, [card.id]);
      
      if (context.mounted) {
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to ${collection.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add ${card.name} to Collection',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _createNewCollection(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Create New Collection'),
                  ],
                ),
              ),
              if (existingCollections.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Or add to existing collection:'),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: existingCollections.length,
                  itemBuilder: (context, index) {
                    final collection = existingCollections[index];
                    return FutureBuilder<List<TcgCard>>(
                      future: CollectionService().getCollectionCards(collection.id),
                      builder: (context, snapshot) {
                        final cards = snapshot.data ?? [];
                        final previewCard = cards.isNotEmpty ? cards.first : null;
                        
                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 70,
                            child: previewCard != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      previewCard.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => 
                                          const Icon(Icons.collections_outlined),
                                    ),
                                  )
                                : const Icon(Icons.collections_outlined),
                          ),
                          title: Text(collection.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${collection.cardIds.length} cards',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (collection.totalValue != null && collection.totalValue! > 0)
                                Text(
                                  '€${collection.totalValue!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _addToExistingCollection(context, collection),
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
