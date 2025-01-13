import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';  // Add this import
import 'package:shimmer/shimmer.dart';  // Add this package to pubspec.yaml
import '../models/card_model.dart';
import '../services/collection_service.dart';  // Add this import

class CardItem extends StatefulWidget {
  final TcgCard card;
  final String? docId;  // Add this field
  final VoidCallback? onRemoved;  // Add this field

  const CardItem({
    super.key, 
    required this.card,
    this.docId,  // Optional document ID for collection cards
    this.onRemoved,  // Callback when card is removed
  });

  @override
  State<CardItem> createState() => _CardItemState();
}

class _CardItemState extends State<CardItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  static const double _maxCardWidth = 200.0;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Remove ${widget.card.name} from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = CollectionService();
        await service.removeCard(widget.docId!);
        widget.onRemoved?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.card.name} removed from collection')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove card')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 600 ? screenWidth / 2.5 : _maxCardWidth;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _controller.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
            child: SizedBox(
              width: cardWidth,
              child: Hero(
                tag: 'card_${widget.card.id}',
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: _isPressed ? 1 : (isDark ? 4 : 3),
                  shadowColor: isDark 
                      ? Colors.black.withOpacity(_isPressed ? 0.2 : 0.4)
                      : Colors.black.withOpacity(_isPressed ? 0.1 : 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigate to detail view with hero animation
                    },
                    onLongPress: widget.docId != null 
                        ? () => _confirmDelete(context) 
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: 2.5 / 3.5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: _buildCardImage(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.card.name} ${widget.card.setNumber.isNotEmpty ? "#${widget.card.setNumber}" : ""}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.card.setName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.card.price != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? Colors.green[900]?.withOpacity(0.3) 
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '€${widget.card.price!.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark 
                                              ? Colors.green[300] 
                                              : Colors.green[700],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardImage() {
    return Image.network(
      widget.card.imageUrl,
      fit: BoxFit.contain,
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
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_rounded,
                size: 24,
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
      },
    );
  }
}