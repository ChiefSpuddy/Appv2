import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';  // Add this import
import 'package:shimmer/shimmer.dart';  // Add this package to pubspec.yaml
import '../models/card_model.dart';
import '../services/collection_service.dart';  // Add this import
import '../screens/card_details_screen.dart';  // Add this import

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

  void _handleTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsScreen(
          card: widget.card,
          docId: widget.docId,
        ),
      ),
    );
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
            _handleTap(context);  // Add this line
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          child: Hero(  // Wrap the AnimatedBuilder with Hero
            tag: 'card_${widget.docId ?? widget.card.id}',
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
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
                          ),
                          if (widget.card.price != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              left: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isDark 
                                      ? [
                                          Colors.black.withOpacity(0.9),
                                          Colors.black.withOpacity(0.6),
                                          Colors.transparent,
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.98),
                                          Colors.white.withOpacity(0.8),
                                          Colors.transparent,
                                        ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6, // Reduced from 12
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '€${widget.card.price!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14, // Reduced from 18
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: isDark 
                                      ? Colors.greenAccent[100]
                                      : Colors.green[800],
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.card.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.card.setName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}