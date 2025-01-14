import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/collection_service.dart';

class PortfolioValueCard extends StatelessWidget {
  const PortfolioValueCard({
    super.key, 
    this.showCardCount = true,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 4),
  });

  final bool showCardCount;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final CollectionService _service = CollectionService();

    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getCollectionStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        
        final stats = snapshot.data ?? {};
        final totalValue = stats['totalValue'] ?? 0.0;
        final dailyChange = stats['dailyChange']?.toDouble() ?? 0.0;
        final dailyChangePercent = stats['dailyChangePercent']?.toDouble() ?? 0.0;
        final isPositive = dailyChange >= 0;

        return Container(
          margin: margin,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [Colors.green.shade900, Colors.green.shade800]
                    : [Colors.green.shade500, Colors.green.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portfolio Value',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€${totalValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (showCardCount && snapshot.hasData)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${stats['totalCards'] ?? 0} Cards',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (!showCardCount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPositive 
                                ? Colors.green.shade300.withOpacity(0.2)
                                : Colors.red.shade300.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive 
                                    ? Icons.trending_up 
                                    : Icons.trending_down,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${isPositive ? '+' : ''}${dailyChangePercent.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
