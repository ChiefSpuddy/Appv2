import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/collection_service.dart';
import '../models/collector_rank.dart';  // Add this import
import 'dart:math' show min, max;

class HomeOverview extends StatefulWidget {
  const HomeOverview({super.key});

  @override
  State<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> with SingleTickerProviderStateMixin {
  final CollectionService _service = CollectionService();
  late AnimationController _animationController;
  List<Map<String, dynamic>>? _currentData;
  List<Map<String, dynamic>>? _previousData;
  int _selectedMonths = 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateChartData(CollectionService service) async {
    final data = await service.getPriceHistory(months: _selectedMonths);
    setState(() {
      _previousData = _currentData;
      _currentData = data;
    });
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getCollectionStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final stats = snapshot.data ?? {
          'totalCards': 0,
          'totalValue': 0.0,
          'monthlyStats': {
            'valueGrowth': 0.0,
            'growthPercentage': 0.0,
          }
        };

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPortfolioHeader(stats),
            const SizedBox(height: 24),
            _buildPriceChart(_service),
            const SizedBox(height: 24),
            _buildQuickStats(stats),
          ],
        );
      },
    );
  }

  Widget _buildPortfolioHeader(Map<String, dynamic> stats) {
    final totalValue = (stats['totalValue'] as num?)?.toDouble() ?? 0.0;
    final monthlyStats = stats['monthlyStats'] as Map<String, dynamic>? ?? {};
    final monthlyChange = (monthlyStats['valueGrowth'] as num?)?.toDouble() ?? 0.0;
    final percentageChange = (monthlyStats['growthPercentage'] as num?)?.toDouble() ?? 0.0;

    final isPositive = monthlyChange >= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '€${totalValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'this month',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChart(CollectionService service) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Value History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 1,
                      label: Text('1M', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 3,
                      label: Text('3M', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 6,
                      label: Text('6M', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 12,
                      label: Text('1Y', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_selectedMonths},
                  onSelectionChanged: (Set<int> selected) {
                    setState(() {
                      _selectedMonths = selected.first;
                    });
                    _updateChartData(service);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    // Add these style properties
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    maximumSize: MaterialStateProperty.all(
                      const Size(double.infinity, 32),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith(
                      (states) {
                        if (states.contains(MaterialState.selected)) {
                          return Theme.of(context).primaryColor;
                        }
                        return Colors.transparent;
                      },
                    ),
                  ),
                  showSelectedIcon: false, // This removes the checkmark
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: service.getPriceHistory(months: _selectedMonths),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No price history available'),
                    );
                  }

                  if (_currentData == null) {
                    _currentData = snapshot.data;
                    // Start animation when data is first loaded
                    _animationController.forward();
                  }

                  final currentSpots = _getCurrentSpots();
                  final previousSpots = _getPreviousSpots();
                  final maxY = _currentData!.map((e) => e['value'] as double).reduce(max);
                  final minY = _currentData!.map((e) => e['value'] as double).reduce(min);

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      final spots = _interpolateSpots(
                        previousSpots,
                        currentSpots,
                        _animationController.value,
                      );

                      return LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60, // Increased space for values
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
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32, // Increased from original
                                interval: max(1, (spots.length / 5).floor()).toDouble(), // Reduced number of labels
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= _currentData!.length) {
                                    return const Text('');
                                  }
                                  final date = _currentData![value.toInt()]['timestamp'] as DateTime;
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
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                              tooltipPadding: const EdgeInsets.all(8),
                              tooltipMargin: 10, // Increased margin
                              // ...existing tooltip configuration...
                            ),
                          ),
                          borderData: FlBorderData(show: false),
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
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: Colors.blue,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[400]!.withOpacity(0.1 * _animationController.value),
                                    Colors.blue[800]!.withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
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
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getCurrentSpots() {
    return _currentData?.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['value'],
      );
    }).toList() ?? [];
  }

  List<FlSpot> _getPreviousSpots() {
    return _previousData?.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['value'],
      );
    }).toList() ?? _getCurrentSpots();
  }

  List<FlSpot> _interpolateSpots(List<FlSpot> previous, List<FlSpot> current, double t) {
    if (previous.isEmpty || current.isEmpty) return current;
    
    final res = <FlSpot>[];
    final maxLen = max(previous.length, current.length);
    
    for (var i = 0; i < maxLen; i++) {
      final prevY = i < previous.length ? previous[i].y : current.last.y;
      final currY = i < current.length ? current[i].y : previous.last.y;
      final interpolatedY = prevY + (currY - prevY) * t;
      
      res.add(FlSpot(i.toDouble(), interpolatedY));
    }
    
    return res;
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            'Total Cards',
            stats['totalCards'].toString(),
            Icons.credit_card,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickStatCard(
            'Avg. Value',
            '€${stats['averageValue'].toStringAsFixed(2)}',
            Icons.analytics,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color[700],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectorScore(Map<String, dynamic> stats) {
    final score = stats['collectorScore'] as Map<String, dynamic>? ?? {};
    final level = score['level'] as int? ?? 0;
    final progress = score['progress'] as double? ?? 0.0;
    final rank = CollectorRank.getRankForLevel(level);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Collector Level', color: rank.color),
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
                        color: rank.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        children: [
                          Text(
                            rank.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          Text(
                            'Lvl $level',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: rank.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rank.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rank.color,
                  ),
                ),
                const SizedBox(height: 16),
                // ... rest of the existing collector score UI ...
              ],
            ),
          ),
        ],
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
}
