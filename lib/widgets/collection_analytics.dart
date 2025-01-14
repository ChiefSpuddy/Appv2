import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/collection_service.dart';
import 'dart:math' show min, max;

class CollectionAnalytics extends StatelessWidget {
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

  const CollectionAnalytics({super.key});

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
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildPriceHistory(_collectionService),
                  const SizedBox(height: 24),
                  _buildCollectorScore(stats),
                  const SizedBox(height: 24),
                  _buildMilestones(stats),
                  const SizedBox(height: 24),
                  _buildBiggestMovers(_collectionService),
                  const SizedBox(height: 24),
                  _buildMonthlyProgress(stats['monthlyStats']),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
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
            child: Center( // Center the ListView
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
    return Column(
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
            child: Row(
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
                Expanded(
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
        final isWideScreen = width > 600;
        final aspectRatio = isWideScreen 
            ? width / 300  // Wider screens get a more panoramic view
            : width / 400; // Narrower screens get a taller chart
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: service.getPriceHistory(),
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

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Price History', color: Colors.orange),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        AspectRatio(
                          aspectRatio: aspectRatio,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: max(1, maxY / 5), // Adjust grid lines
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[300],
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  );
                                },
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
                                    reservedSize: 32, // Increased reserved size
                                    interval: max(1, (spots.length / 5).floor()).toDouble(), // Reduced number of labels
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= data.length) return const Text('');
                                      final date = data[value.toInt()]['timestamp'] as DateTime;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '${date.day}/${date.month}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 65, // Increased for wider values
                                    interval: maxY > 1000 ? maxY / 5 : max(1, maxY / 5),
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          value >= 1000
                                              ? '€${(value/1000).toStringAsFixed(1)}k'
                                              : '€${value.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Add padding to prevent overlap
                              minY: minY * 0.95,
                              maxY: maxY * 1.05,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  gradient: LinearGradient(
                                    colors: [Colors.blue[400]!, Colors.blue[800]!],
                                  ),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: Colors.white,
                                        strokeWidth: 2,
                                        strokeColor: Colors.blue[800]!,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue[400]!.withOpacity(0.2),
                                        Colors.blue[800]!.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: maxY,
                                    color: Colors.green.withOpacity(0.5),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                                      style: TextStyle(
                                        color: isDark ? Colors.green[300] : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      labelResolver: (line) => '€${maxY.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  // Remove the minimum value line to keep the chart cleaner
                                ],
                              ),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                                  tooltipRoundedRadius: 8,
                                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots.map((LineBarSpot touchedSpot) {
                                      final date = data[touchedSpot.x.toInt()]['timestamp'] as DateTime;
                                      return LineTooltipItem(
                                        '€${touchedSpot.y.toStringAsFixed(2)}\n',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${date.day}/${date.month}/${date.year}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
                  ),
                ],
              ),
            );
          },
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
            if (monthlyStats['growthPercentage'] != 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Growth: ${monthlyStats['growthPercentage'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: monthlyStats['growthPercentage'] >= 0 
                        ? Colors.green[700] 
                        : Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    'No significant price changes in the last 7 days',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
                ...snapshot.data!.map((mover) {
                  final isPositive = mover['priceChange'] >= 0;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            mover['imageUrl'],
                            width: 40,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                        title: Text(
                          mover['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
                              '€${mover['priceChange'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${mover['percentageChange'].toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isPositive ? Colors.green[700] : Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mover != snapshot.data!.last)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add this new method for collector score
  Widget _buildCollectorScore(Map<String, dynamic> stats) {
    final score = stats['collectorScore'] as Map<String, dynamic>? ?? {};
    final level = score['level'] as int? ?? 0;
    final progress = score['progress'] as double? ?? 0.0;
    final nextLevelPoints = score['nextLevelPoints'] as int? ?? 100;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Collector Level', color: _modernChartColors[0]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _modernChartColors[0].withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'Lvl $level',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _modernChartColors[0],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_modernChartColors[0]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()} / 100 points to level ${level + 1}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Score Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildScoreComponent('Rarity Bonus', score['rarityBonus'] ?? 0, _modernChartColors[1]),
                _buildScoreComponent('Set Completion', score['completionBonus'] ?? 0, _modernChartColors[2]),
                _buildScoreComponent('Collection Value', score['valueBonus'] ?? 0, _modernChartColors[3]),
                _buildScoreComponent('First Editions', score['firstEditionBonus'] ?? 0, _modernChartColors[4]),
                _buildScoreComponent('Set Diversity', score['diversityBonus'] ?? 0, _modernChartColors[5]),
                _buildScoreComponent('Card Grades', score['gradeBonus'] ?? 0, _modernChartColors[6]),
                _buildScoreComponent('Activity Streak', score['streakBonus'] ?? 0, _modernChartColors[7]),
              ],
            ),
          ),
        ],
      ),
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
