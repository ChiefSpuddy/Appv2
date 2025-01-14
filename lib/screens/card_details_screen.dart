import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' show min, max;
import '../services/collection_service.dart'; // Add this import

class CardDetailsScreen extends StatefulWidget {
  final TcgCard card;
  final String? docId;

  const CardDetailsScreen({
    super.key,
    required this.card,
    this.docId,
  });

  @override
  State<CardDetailsScreen> createState() => _CardDetailsState();
}

class _CardDetailsState extends State<CardDetailsScreen> {
  final _apiService = ApiService();
  final _collectionService = CollectionService(); // Add this
  Map<String, dynamic>? _priceData;
  bool _isLoading = true;
  bool _isInCollection = false; // Add this

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkCollectionStatus(); // Add this
  }

  // Add this method
  Future<void> _checkCollectionStatus() async {
    if (widget.docId != null) {
      setState(() => _isInCollection = true);
    } else {
      final exists = await _collectionService.cardExists(widget.card.id);
      if (mounted) setState(() => _isInCollection = exists);
    }
  }

  // Add this method
  Future<void> _toggleCollection() async {
    try {
      if (_isInCollection) {
        if (widget.docId != null) {
          await _collectionService.removeCard(widget.docId!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Removed ${widget.card.name} from collection')),
            );
          }
        }
      } else {
        await _collectionService.addCard(widget.card);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${widget.card.name} to collection')),
          );
        }
      }
      if (mounted) {
        setState(() => _isInCollection = !_isInCollection);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update collection')),
        );
      }
    }
  }

  Future<void> _loadData() async {
    final pricing = await _apiService.getCardPricing(widget.card.id);
    if (mounted) {
      setState(() {
        _priceData = pricing;
        _isLoading = false;
      });
    }
  }

  Widget _buildPricingSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_priceData == null) {
      return const Center(child: Text('Price data unavailable'));
    }

    final prices = _priceData!['prices'] as Map<String, dynamic>;
    final updatedAt = _priceData!['updatedAt'] as String?;
    final marketUrl = _priceData!['url'] as String?;

    // Show only real available prices
    final relevantPrices = {
      if (widget.card.price != null)
        'Current Value': widget.card.price,
      if (prices['averageSellPrice'] != null)
        'Market Price': prices['averageSellPrice'],
      if (prices['lowPrice'] != null)
        'Lowest Price': prices['lowPrice'],
      if (prices['trendPrice'] != null)
        'Trend Price': prices['trendPrice'],
    };

    // Add price trends section
    final trends = {
      if (prices['avg1'] != null)
        '24h Average': prices['avg1'],
      if (prices['avg7'] != null)
        '7 Day Average': prices['avg7'],
      if (prices['avg30'] != null)
        '30 Day Average': prices['avg30'],
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Market Prices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...relevantPrices.entries
            .where((e) => e.value != null)
            .map((entry) => _buildPriceRow(
              entry.key,
              entry.value,
              isHighlighted: entry.key == 'Current Value',
            )),
          if (trends.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'Price Trends',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...trends.entries
              .where((e) => e.value != null)
              .map((entry) => _buildPriceRow(entry.key, entry.value)),
          ],
          if (updatedAt != null) ...[
            const Divider(height: 24),
            Text(
              'Last updated: ${_formatDate(updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (marketUrl != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(marketUrl),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('View on Cardmarket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.green[700] : Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(_getEbaySearchUrl()),
                    icon: const Icon(Icons.search),
                    label: const Text('Search on eBay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0064D2),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = dateStr.contains('/')
          ? DateTime(
              int.parse(dateStr.split('/')[0]),
              int.parse(dateStr.split('/')[1]),
              int.parse(dateStr.split('/')[2]),
            )
          : DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date unavailable';
    }
  }

  String _getPriceTooltip(String label) {
    switch (label) {
      case 'Current Value':
        return 'The value you entered for this card in your collection';
      case 'Market Price':
        return 'The average price that this card has recently sold for';
      case 'Lowest Price':
        return 'The lowest available price from verified sellers';
      case 'Trend Price':
        return 'The weighted average price over the last few days';
      case '24h Average':
        return 'Average price over the last 24 hours';
      case '7 Day Average':
        return 'Average price over the last 7 days';
      case '30 Day Average':
        return 'Average price over the last 30 days';
      default:
        return '';
    }
  }

  String _getEbaySearchUrl() {
    final searchQuery = Uri.encodeComponent('${widget.card.name} ${widget.card.setName} pokemon card');
    return 'https://www.ebay.com/sch/i.html?_nkw=$searchQuery';
  }

  Widget _buildPriceRow(String label, dynamic price, {bool isHighlighted = false}) {
    if (price == null) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tooltip = _getPriceTooltip(label);
    
    return Tooltip(
      message: tooltip,
      textStyle: TextStyle(
        color: isDark ? Colors.black : Colors.white,
        fontSize: 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[200] : Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isHighlighted ? BoxDecoration(
          color: isDark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.green[700]! : Colors.green[200]!,
            width: 1,
          ),
        ) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isHighlighted ? 8 : 0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: isHighlighted ? const TextStyle(
                        fontWeight: FontWeight.bold,
                      ) : null,
                    ),
                    if (tooltip.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '€${(price as num).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHighlighted 
                    ? (isDark ? Colors.green[300] : Colors.green[700])
                    : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth < 600 ? screenWidth * 0.6 : 300.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: isDark ? Colors.black : Colors.grey[100],
              child: Center(
                child: Hero(
                  tag: 'card_${widget.docId ?? widget.card.id}',
                  child: SizedBox(
                    width: imageWidth,
                    child: AspectRatio(
                      aspectRatio: 0.71,
                      child: Card(
                        elevation: 8,
                        margin: const EdgeInsets.all(16),
                        child: Image.network(
                          widget.card.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Name Section
                  Text(
                    widget.card.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Section
                  if (widget.card.price != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green[900] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.green[700]! : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Portfolio Value: ',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.green[100] : Colors.green[900],
                            ),
                          ),
                          Text(
                            '€${widget.card.price!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.green[100] : Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildPricingSection(context),
                  const SizedBox(height: 24),
                  
                  // Card Details Section
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          context,
                          'Set',
                          widget.card.setName,
                          Icons.style,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Rarity',
                          widget.card.rarity,
                          Icons.stars,
                        ),
                        if (widget.card.id.isNotEmpty) ...[
                          const Divider(),
                          _buildDetailRow(
                            context,
                            'Card ID',
                            widget.card.id,
                            Icons.tag,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isInCollection ? Colors.red : Colors.green)
                  .withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _toggleCollection,
          icon: Icon(
            _isInCollection ? Icons.remove : Icons.add,
            size: 18,
          ),
          label: Text(
            _isInCollection ? 'Remove' : 'Add to Collection',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _isInCollection 
            ? Colors.red 
            : Colors.green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          extendedPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add this extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}
