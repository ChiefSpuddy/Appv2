import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/card_model.dart';
import '../services/collection_service.dart';
import '../screens/card_details_screen.dart';
import './collection_selection_sheet.dart';  // Add this import

class CardItem extends StatelessWidget {
  final TcgCard card;
  final String? docId;
  final VoidCallback? onRemoved;

  const CardItem({
    super.key, 
    required this.card,
    this.docId,
    this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildErrorWidget() => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 28,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 4),
          Text(
            'Image Error',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      elevation: isDark ? 1 : 2,
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardDetailsScreen(
                card: card,
                docId: docId,
              ),
            ),
          );
        },
        onLongPress: () => _showOptions(context), // Add this
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 8, // Increased flex ratio for image
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'card_${card.id}',
                    child: ClipRRect(  // Add this wrapper
                      borderRadius: const BorderRadius.vertical(  // Add rounded corners to top only
                        top: Radius.circular(8),
                      ),
                      child: Image.network(
                        card.imageUrl,
                        fit: BoxFit.contain, // Changed to contain
                        alignment: Alignment.center,
                        headers: const {
                          'Access-Control-Allow-Origin': '*',
                          'Referrer-Policy': 'no-referrer',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return Container(  // Wrap image in container for consistent corners
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                color: isDark ? Colors.black : Colors.white,
                              ),
                              child: child,
                            );
                          }
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => buildErrorWidget(),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardDetailsScreen(
                              card: card,
                              docId: docId,
                            ),
                          ),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (card.price != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.green[900] : Colors.green[50])?.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '€${card.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isDark ? Colors.green[400] : Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.collections_bookmark),
              title: const Text('Add to Custom Collection'),
              onTap: () {
                Navigator.pop(context);
                _addToCollection(context, card);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Card', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete ${card.name}?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted && docId != null) {
      try {
        await CollectionService().removeCard(docId!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted ${card.name}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete card'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addToCollection(BuildContext context, TcgCard card) async {
    final service = CollectionService();
    
    // First get existing collections
    final collections = await service.getCustomCollections();
    
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => CollectionSelectionSheet(
          card: card,
          existingCollections: collections,
        ),
      );
    }
  }
}