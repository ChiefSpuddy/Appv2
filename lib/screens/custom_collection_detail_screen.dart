import 'package:flutter/material.dart';
import '../models/custom_collection.dart';
import '../widgets/collection_grid.dart';

class CustomCollectionDetailScreen extends StatelessWidget {
  final CustomCollection collection;

  const CustomCollectionDetailScreen({
    super.key,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit collection
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (collection.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(collection.description),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${collection.cardIds.length} cards',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (collection.totalValue != null)
                  Text(
                    '€${collection.totalValue!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: CollectionGrid(),
          ),
        ],
      ),
    );
  }
}
