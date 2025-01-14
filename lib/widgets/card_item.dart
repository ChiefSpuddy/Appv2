import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/card_model.dart';
import '../services/collection_service.dart';
import '../screens/card_details_screen.dart';

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
                    child: Image.network(
                      card.imageUrl,
                      fit: BoxFit.contain, // Changed to contain
                      alignment: Alignment.center,
                      headers: const {
                        'Access-Control-Allow-Origin': '*',
                        'Referrer-Policy': 'no-referrer',
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => buildErrorWidget(),
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
}