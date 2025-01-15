import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/collection_service.dart';
import 'dart:math' show min, max, log, pow;

class CollectionAnalytics extends StatefulWidget {  // Change to StatefulWidget
  const CollectionAnalytics({super.key});

  @override
  State<CollectionAnalytics> createState() => _CollectionAnalyticsState();
}

class _CollectionAnalyticsState extends State<CollectionAnalytics> {
  static const Map<String, int> periodMonths = {
    '1M': 1,
    '3M': 3,
    '6M': 6,
    '1Y': 12,
  };
  
  // Add these new fields
  late Future<List<Map<String, dynamic>>> _priceHistoryFuture;
  final ValueNotifier<int> _selectedPeriod = ValueNotifier(3);

  @override
  void initState() {
    super.initState();
    _priceHistoryFuture = CollectionService().getPriceHistory(months: _selectedPeriod.value);
  }

  static final List<MaterialColor> _chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];

  // Replace the existing color palette with this modern one
  static final List<Color> _modernChartColors = [
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF42A5F5), // Blue
    const Color(0xFF26A69A), // Teal
    const Color(0xFF66BB6A), // Green
    const Color(0xFFFFCA28), // Amber
    const Color(0xFFEF5350), // Red
    const Color(0xFF8D6E63), // Brown
    const Color(0xFF78909C), // Blue Grey
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final CollectionService _collectionService = CollectionService();
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _collectionService.getCollectionStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }
        
        final stats = snapshot.data!;
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView( // Add this wrapper
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Add this
                children: [
                  _buildSummaryCards(stats),
                  const SizedBox(height: 16),
                  _buildPriceHistory(_collectionService),
                  const SizedBox(height: 16),
                  _buildMonthlyProgress(stats['monthlyStats']), // Moved up
                  const SizedBox(height: 24),
                  _buildCollectorScore(stats),
                  const SizedBox(height: 24),
                  _buildMilestones(stats),
                  const SizedBox(height: 24),
                  _buildBiggestMovers(_collectionService),
                  const SizedBox(height: 24),
                  _buildRarityValues(stats['rarityValues'] ?? {}),
                  const SizedBox(height: 24),
                  _buildSetDistribution(stats['setDistribution'] ?? {}),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color ?? Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    final dailyChange = stats['dailyChange']?.toDouble() ?? 0.0;
    final dailyChangePercent = stats['dailyChangePercent']?.toDouble() ?? 0.0;
    final topRarities = stats['topRarities'] as List<dynamic>? ?? [];
    final isPositive = dailyChange >= 0;

    return Column(
      children: [
        // Portfolio Value Card - More prominent and greener
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade600,
                  Colors.green.shade800,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Portfolio Value',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '€${stats['totalValue'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_down,
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
                if (stats['monthlyGrowth'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stats['monthlyGrowth'] >= 0 ? '+' : ''}${stats['monthlyGrowth'].toStringAsFixed(1)}% this month',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Wrap stats list in a Container with padding
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactStatCard(
                      'Total Cards',
                      stats['totalCards'].toString(),
                      Icons.credit_card,
                      Colors.blue,
                      subtitle: 'In collection',
                    ),
                    _buildCompactStatCard(
                      'Unique Sets',
                      stats['uniqueSets']?.toString() ?? '0',
                      Icons.folder,
                      Colors.purple,
                      subtitle: 'Different sets',
                    ),
                    _buildCompactStatCard(
                      '24h Change',
                      '€${dailyChange.toStringAsFixed(2)}',
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      isPositive ? Colors.green : Colors.red,
                      subtitle: '${isPositive ? '+' : ''}${dailyChangePercent.toStringAsFixed(1)}%',
                    ),
                    _buildCompactStatCard(
                      'Top Rarity',
                      topRarities.isNotEmpty ? '${topRarities[0]['count']}' : '0',
                      Icons.stars,
                      Colors.amber,
                      subtitle: topRarities.isNotEmpty 
                        ? '${topRarities[0]['name']}'
                        : 'No cards',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Update the compact stat card to have fixed dimensions
  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    MaterialColor color,
    {String? subtitle}
  ) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Tooltip(
          message: '$title: $value${subtitle != null ? '\n$subtitle' : ''}',
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Show detailed info in a bottom sheet
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 48, color: color),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 24,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                width: 85,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark ? [
                      color[900]!.withOpacity(0.5),
                      color[800]!.withOpacity(0.3),
                    ] : [
                      color[50]!,
                      color[100]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isDark ? color[300] : color[700],
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 12, // Smaller font
                          fontWeight: FontWeight.bold,
                          color: isDark ? color[300] : color[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 9, // Smaller font
                          color: isDark ? color[400] : color[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetDistribution(Map<String, dynamic> setData) {
    if (setData.isEmpty) {
      return _buildEmptyState('No set data available');
    }

    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      return StatefulBuilder(
        builder: (context, setState) {
          bool showValueDistribution = false;
          
          // Safely extract data and handle types
          final Map<String, int> countData = Map<String, int>.from(
            Map.fromEntries(
              setData.entries.where((e) => e.key != 'setValues' && e.value is int)
            )
          );
          
          final Map<String, double> valueData = Map<String, double>.from(
            (setData['setValues'] as Map<dynamic, dynamic>? ?? {}).map(
              (key, value) => MapEntry(key.toString(), (value as num).toDouble())
            )
          );

          // Create sorted lists based on the view type
          List<MapEntry<String, dynamic>> sortedSets;
          dynamic total;
          
          if (showValueDistribution) {
            var entries = valueData.entries.toList();
            entries.sort((a, b) => b.value.compareTo(a.value));
            sortedSets = entries;
            total = entries.fold<double>(0, (sum, item) => sum + item.value);
          } else {
            var entries = countData.entries.toList();
            entries.sort((a, b) => b.value.compareTo(a.value));
            sortedSets = entries;
            total = entries.fold<int>(0, (sum, item) => sum + item.value);
          }

          final topSets = sortedSets.take(8).toList();
          final sections = <PieChartSectionData>[];
          
          for (var i = 0; i < topSets.length; i++) {
            final value = showValueDistribution
                ? topSets[i].value
                : topSets[i].value.toDouble();
            final percentage = ((value / total) * 100).round();
            
            sections.add(
              PieChartSectionData(
                value: value,
                title: percentage >= 10 ? '$percentage%' : '',
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
                radius: 100,
                color: _modernChartColors[i % _modernChartColors.length],
                showTitle: true,
                badgeWidget: percentage < 10 ? null : _buildBadge(percentage),
                badgePositionPercentageOffset: 0.9,
              ),
            );
          }

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSectionHeader('Set Distribution', color: _modernChartColors[0]),
                      ),
                      ToggleButtons(
                        isSelected: [!showValueDistribution, showValueDistribution],
                        onPressed: (index) {
                          setState(() => showValueDistribution = index == 1);
                        },
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minWidth: 60, minHeight: 32),
                        children: const [
                          Text(' Count '),
                          Text(' Value '),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300, // Fixed height
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: PieChart(
                                PieChartData(
                                  sections: sections,
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  centerSpaceColor: isDark ? Theme.of(context).cardColor : Colors.white,
                                  pieTouchData: PieTouchData(enabled: false), // Disable touch interactions
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildSetLegend(
                                  context, 
                                  topSets,
                                  total,
                                  showValueDistribution,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Cards: $total',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAllSets(context, sortedSets),
                            child: const Text('View All Sets'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBadge(int percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$percentage%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSetLegend(
    BuildContext context,
    List<MapEntry<String, dynamic>> sets,
    dynamic total,
    bool showValue,
  ) {
    return SingleChildScrollView(  // Add scrolling capability
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: sets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;
          final value = set.value;
          final percentage = ((value / total) * 100).toStringAsFixed(1);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () => _showSetDetailsTyped(context, set, showValue),
              borderRadius: BorderRadius.circular(4),
              child: LayoutBuilder(  // Add LayoutBuilder
                builder: (context, constraints) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _modernChartColors[index % _modernChartColors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(  // Replace Expanded with Flexible
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              set.key,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              showValue
                                  ? '€${value.toStringAsFixed(2)} · $percentage%'
                                  : '${value} cards · $percentage%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSetDetailsTyped(
    BuildContext context, 
    MapEntry<String, dynamic> set,
    bool isValueView,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              set.key,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isValueView
                  ? 'Total Value: €${(set.value as double).toStringAsFixed(2)}'
                  : 'Number of Cards: ${set.value}',
            ),
          ],
        ),
      ),
    );
  }

  void _showAllSets(BuildContext context, List<MapEntry<String, dynamic>> allSets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'All Sets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: allSets.length,
                itemBuilder: (context, index) {
                  final set = allSets[index];
                  return ListTile(
                    title: Text(set.key),
                    trailing: Text(
                      set.value is double
                          ? '€${(set.value as double).toStringAsFixed(2)}'
                          : '${set.value} cards'
                    ),
                    onTap: () => _showSetDetailsTyped(context, set, set.value is double),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceHistory(CollectionService service) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final aspectRatio = width > 600 ? 2.5 : 1.8;  // Adjusted aspect ratio
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildSectionHeader('Price History', color: _modernChartColors[1]),
                    const Spacer(),
                    _buildPeriodSelector(),
                  ],
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _selectedPeriod,
                builder: (context, period, _) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    key: ValueKey('price_history_$period'),
                    future: service.getPriceHistory(months: period),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timeline_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No price history available yet.\nAdd or remove cards to see the value change over time.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final minY = data.map((e) => e['value'] as double).reduce(min);
                      final maxY = data.map((e) => e['value'] as double).reduce(max);
                      final spots = data.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['value']);
                      }).toList();

                      // Calculate growth more accurately
                      final firstValue = data.first['value'] as double;
                      final lastValue = data.last['value'] as double;
                      final growthPercentage = firstValue > 0 
                          ? ((lastValue - firstValue) / firstValue * 100)
                          : 0.0;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Growth',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                growthPercentage >= 0 
                                                    ? Icons.arrow_upward 
                                                    : Icons.arrow_downward,
                                                size: 16,
                                                color: growthPercentage >= 0 
                                                    ? Colors.green[400] 
                                                    : Colors.red[400],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${growthPercentage.abs().toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: growthPercentage >= 0 
                                                      ? Colors.green[400] 
                                                      : Colors.red[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Value Change',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '€${(lastValue - firstValue).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: growthPercentage >= 0 
                                                  ? Colors.green[400] 
                                                  : Colors.red[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: max(1, maxY / 4),
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                        strokeWidth: 0.8,
                                        dashArray: [5, 5],
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: max(1, (spots.length / 6).floor()).toDouble(),
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= data.length) return const Text('');
                                            final date = data[value.toInt()]['timestamp'] as DateTime;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 5),
                                              child: Text(
                                                '${date.day}/${date.month}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 46,
                                          interval: ((maxY - minY) / 6).roundToDouble(), // Add dynamic interval
                                          getTitlesWidget: (value, meta) {
                                            // Skip labels that are too close to max or min
                                            if (value > maxY || value < minY) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: Text(
                                                value >= 1000
                                                    ? '€${(value/1000).toStringAsFixed(1)}k'
                                                    : '€${value.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minY: minY * 0.95,
                                    maxY: maxY * 1.05,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        gradient: LinearGradient(
                                          colors: [
                                            _modernChartColors[1],
                                            _modernChartColors[0],
                                          ],
                                        ),
                                        barWidth: 2.5,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                            radius: 2.5,
                                            color: _modernChartColors[0],
                                            strokeWidth: 1,
                                            strokeColor: Colors.white,
                                          ),
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              _modernChartColors[0].withOpacity(0.2),
                                              _modernChartColors[0].withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: const EdgeInsets.all(8),
                                        tooltipBorder: BorderSide(
                                          color: isDark ? Colors.white10 : Colors.black12,
                                        ),
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final date = data[spot.x.toInt()]['timestamp'] as DateTime;
                                            return LineTooltipItem(
                                              '€${spot.y.toStringAsFixed(2)}\n',
                                              TextStyle(
                                                color: isDark ? Colors.white : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: '${date.day}/${date.month}/${date.year}',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList();
                                        },
                                      ),
                                      getTouchedSpotIndicator: (barData, spotIndexes) {
                                        return spotIndexes.map((index) {
                                          return TouchedSpotIndicatorData(
                                            FlLine(
                                              color: isDark ? Colors.white24 : Colors.black12,
                                              strokeWidth: 1,
                                              dashArray: [3, 3],
                                            ),
                                            FlDotData(
                                              show: true,
                                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                                radius: 4,
                                                color: _modernChartColors[0],
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              ),
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedPeriod,
      builder: (context, selectedPeriod, _) {
        return SegmentedButton<int>(
          segments: periodMonths.entries.map((e) => 
            ButtonSegment<int>(
              value: e.value,
              label: Text(e.key),
            ),
          ).toList(),
          selected: {selectedPeriod},
          onSelectionChanged: (Set<int> selection) {
            _selectedPeriod.value = selection.first;
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            // Add these style properties for better appearance
            backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.selected)) {
                return _modernChartColors[1];
              }
              return null;
            }),
            foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white;
              }
              return null;
            }),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyProgress(Map<String, dynamic> monthlyStats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Monthly Progress', color: Colors.indigo),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressItem(
                    'Cards Added',
                    monthlyStats['cardsAdded'].toString(),
                    Icons.add_chart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildProgressItem(
                    'Value Added',
                    '€${monthlyStats['valueAdded'].toStringAsFixed(2)}',
                    Icons.trending_up,
                    monthlyStats['valueGrowth'] >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityValues(Map<String, double> rarityValues) {
    if (rarityValues.isEmpty) return const SizedBox.shrink();

    final sortedRarities = rarityValues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Rarity Values', color: Colors.amber),
            const SizedBox(height: 16),
            ...sortedRarities.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key),
                  ),
                  Expanded(
                    child: Text(
                      '€${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBiggestMovers(CollectionService service) {
    const minPriceThreshold = 1.0; // Minimum price threshold in EUR
    const minPriceChangeThreshold = 1.0; // Minimum absolute price change to consider
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.getBiggestMovers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildEmptyMoversCard('No price movement data available');
        }

        // Filter and process the movers data
        final significantMovers = snapshot.data!
            .where((mover) {
              final currentPrice = mover['currentPrice'] as double;
              final oldPrice = mover['oldPrice'] as double;
              final priceChange = (currentPrice - oldPrice).abs();
              
              // Only include cards that:
              // 1. Are worth more than minPriceThreshold
              // 2. Have changed by at least minPriceChangeThreshold
              return currentPrice >= minPriceThreshold && 
                     priceChange >= minPriceChangeThreshold;
            })
            .toList()
          ..sort((a, b) {
              // Sort by absolute percentage change
              final aChange = (a['percentageChange'] as double).abs();
              final bChange = (b['percentageChange'] as double).abs();
              return bChange.compareTo(aChange);
            });

        if (significantMovers.isEmpty) {
          return _buildEmptyMoversCard(
            'No significant price movements in the last 7 days\n'
            '(minimum €$minPriceThreshold value, €$minPriceChangeThreshold change)'
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader('Biggest Movers (7 Days)', color: Colors.pink),
                const SizedBox(height: 16),
                ...significantMovers.take(5).map((mover) {  // Only show top 5 movers
                  final isPositive = mover['priceChange'] >= 0;
                  final priceChange = mover['priceChange'] as double;
                  final percentageChange = mover['percentageChange'] as double;
                  
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                mover['imageUrl'],
                                width: 40,
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isPositive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          mover['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              '€${mover['oldPrice'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            Text(
                              '€${mover['currentPrice'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 90,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '€${priceChange.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${isPositive ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: isPositive ? Colors.green[700] : Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (mover != significantMovers.take(5).last)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
                if (significantMovers.length > 5) ...[
                  const Divider(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => _showAllMovers(context, significantMovers),
                      child: Text('View All ${significantMovers.length} Movers'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyMoversCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader('Biggest Movers (7 Days)', color: Colors.pink),
            const SizedBox(height: 16),
            Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAllMovers(BuildContext context, List<Map<String, dynamic>> allMovers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All Price Movements',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: allMovers.length,
                itemBuilder: (context, index) {
                  final mover = allMovers[index];
                  final isPositive = mover['priceChange'] >= 0;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        mover['imageUrl'],
                        width: 30,
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: Text(
                      mover['name'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '€${mover['oldPrice'].toStringAsFixed(2)} → €${mover['currentPrice'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${mover['priceChange'].abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${mover['percentageChange'].toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPositive ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method for collector score
  Widget _buildCollectorScore(Map<String, dynamic> stats) {
    final score = stats['collectorScore'] as Map<String, dynamic>? ?? {};
    final level = score['level'] as int? ?? 0;
    final currentXp = score['currentXp'] as int? ?? 0;
    final requiredXp = score['requiredXp'] as int? ?? 100;
    final progress = currentXp / requiredXp;
    final unlockedPerks = Map<String, String>.from(score['unlockedPerks'] ?? {});

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Collector Level', color: _modernChartColors[0]),
                Tooltip(
                  message: 'Collector Level increases as you earn XP from various activities:\n\n'
                      '• Adding cards to your collection\n'
                      '• Completing sets\n'
                      '• Daily login streaks\n'
                      '• Special achievements\n'
                      '• Collection value milestones\n\n'
                      'Unlock new features and bonuses as you level up!',
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLevelBadge(level),
                const SizedBox(height: 16),
                _buildXpProgress(currentXp, requiredXp, progress),
                const SizedBox(height: 24),
                _buildPerksSection(unlockedPerks, level),
                const Divider(height: 32),
                _buildXpBreakdown(score),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(int level) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _modernChartColors[0],
                _modernChartColors[1],
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _modernChartColors[0].withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '$level',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        CircularProgressIndicator(
          value: (level % 5) / 5,
          strokeWidth: 2,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      ],
    );
  }

  Widget _buildXpProgress(int currentXp, int requiredXp, double progress) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_modernChartColors[0]),
        ),
        const SizedBox(height: 8),
        Text(
          '$currentXp / $requiredXp XP',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActiveMultipliers(Map<String, double> multipliers) {
    final formattedMultipliers = multipliers.map((key, value) => MapEntry(
      _formatMultiplierName(key),
      value,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Active Multipliers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'XP Multipliers stack and boost your earned XP:\n\n'
                  '• Weekend Bonus: 1.5x XP on weekends\n'
                  '• Activity Streak: Up to 2x XP for daily logins\n'
                  '• Special Events: Look out for limited-time multipliers!',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...formattedMultipliers.entries.map((entry) => Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '${entry.value.toStringAsFixed(1)}x',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )),
      ],
    );
  }

  String _formatMultiplierName(String key) {
    switch (key) {
      case 'weekend_bonus':
        return 'Weekend Bonus';
      case 'event_bonus':
        return 'Event Bonus';
      case 'streak_bonus':
        return 'Streak Bonus';
      default:
        return key.split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Widget _buildPerksSection(Map<String, String> unlockedPerks, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unlocked Perks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...unlockedPerks.entries.map((entry) => ListTile(
          leading: Icon(
            Icons.check_circle,
            color: _modernChartColors[0],
          ),
          title: Text(entry.key),
          subtitle: Text(entry.value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildXpBreakdown(Map<String, dynamic> score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'XP Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'XP is earned from multiple sources:\n\n'
                  '• Rarity Bonus: Higher rarity cards give more XP\n'
                  '• Set Completion: Complete sets for big XP bonuses\n'
                  '• Collection Value: Earn XP based on total value\n'
                  '• First Editions: Special bonus for first editions\n'
                  '• Set Diversity: Bonus for collecting different sets\n'
                  '• Card Grades: Better grades mean more XP\n'
                  '• Activity Streak: Daily login bonuses',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        _buildScoreComponent('Rarity Bonus', score['rarityBonus'] ?? 0, _modernChartColors[1]),
        _buildScoreComponent('Set Completion', score['completionBonus'] ?? 0, _modernChartColors[2]),
        _buildScoreComponent('Collection Value', score['valueBonus'] ?? 0, _modernChartColors[3]),
        _buildScoreComponent('First Editions', score['firstEditionBonus'] ?? 0, _modernChartColors[4]),
        _buildScoreComponent('Set Diversity', score['diversityBonus'] ?? 0, _modernChartColors[5]),
        _buildScoreComponent('Card Grades', score['gradeBonus'] ?? 0, _modernChartColors[6]),
        _buildScoreComponent('Activity Streak', score['streakBonus'] ?? 0, _modernChartColors[7]),
      ],
    );
  }

  Widget _buildScoreComponent(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '+$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Add this new method for collection milestones
  Widget _buildMilestones(Map<String, dynamic> stats) {
    final nextMilestone = stats['nextMilestone'] as Map<String, dynamic>?;
    final recentMilestones = stats['recentMilestones'] as List<dynamic>? ?? [];
    final totalCards = stats['totalCards'] as int? ?? 0;
    final targetCards = nextMilestone?['target'] as int? ?? 100;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Collection Milestones', color: _modernChartColors[4]),
          if (nextMilestone != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Next Milestone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _modernChartColors[4].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalCards/$targetCards cards',
                          style: TextStyle(
                            color: _modernChartColors[4],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: nextMilestone['progress']?.toDouble() ?? 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_modernChartColors[4]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextMilestone['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          if (recentMilestones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Achievements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recentMilestones.map((milestone) => ListTile(
                    leading: Icon(
                      Icons.emoji_events,
                      color: _modernChartColors[4],
                    ),
                    title: Text(milestone['title'] ?? ''),
                    subtitle: Text(milestone['date'] ?? ''),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<PieChartSectionData> sections) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 0.5,
        centerSpaceRadius: 40,
        centerSpaceColor: isDark ? Theme.of(context).cardColor : Colors.white,
        pieTouchData: PieTouchData(enabled: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
