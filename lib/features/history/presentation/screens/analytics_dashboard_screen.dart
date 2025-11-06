// lib/features/history/presentation/screens/analytics_dashboard_screen.dart
// Analytics dashboard showing wellness trends and statistics

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../../../core/utils/feature_gate.dart';
import '../../domain/entities/scan_history_entry.dart';
import '../../data/services/history_storage_service.dart';

/// Analytics dashboard screen
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  final _historyService = HistoryStorageService();
  List<ScanHistoryEntry> _scans = [];
  HistoryStatistics? _statistics;
  bool _isLoading = true;
  TimeRange _timeRange = TimeRange.month;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _historyService.initialize();
      final scans = await _historyService.getAllScans();
      final stats = await _historyService.getStatistics();

      setState(() {
        _scans = scans;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAdvancedAnalytics =
        FeatureGate.isFeatureUnlocked(ref, ProFeature.advancedAnalytics);
    final isPro = FeatureGate.isPro(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          if (!isPro)
            TextButton.icon(
              onPressed: _showUpgradeDialog,
              icon: const Icon(Icons.star, color: Colors.amber, size: 20),
              label: const Text('Go Pro'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
              ),
            ),
          if (hasAdvancedAnalytics)
            PopupMenuButton<TimeRange>(
              icon: const Icon(Icons.calendar_today),
              onSelected: (range) => setState(() => _timeRange = range),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: TimeRange.week,
                  child: Text('Last 7 Days'),
                ),
                const PopupMenuItem(
                  value: TimeRange.month,
                  child: Text('Last 30 Days'),
                ),
                const PopupMenuItem(
                  value: TimeRange.threeMonths,
                  child: Text('Last 90 Days'),
                ),
                const PopupMenuItem(
                  value: TimeRange.year,
                  child: Text('Last Year'),
                ),
                const PopupMenuItem(
                  value: TimeRange.all,
                  child: Text('All Time'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scans.isEmpty
              ? _EmptyAnalyticsView()
              : !hasAdvancedAnalytics
                  ? _LockedAnalyticsView(
                      onUpgrade: _showUpgradeDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overview cards
                            _OverviewSection(
                              statistics: _statistics!,
                              scans: _getScansInTimeRange(),
                            ),

                        const SizedBox(height: 24),

                        // Quality trend chart
                        _QualityTrendChart(
                          scans: _getScansInTimeRange(),
                        ),

                        const SizedBox(height: 24),

                        // Insights over time
                        _InsightsTrendChart(
                          scans: _getScansInTimeRange(),
                        ),

                        const SizedBox(height: 24),

                        // Body systems breakdown
                        _BodySystemsBreakdown(
                          scans: _getScansInTimeRange(),
                        ),

                        const SizedBox(height: 24),

                        // Activity heatmap
                        _ActivityHeatmap(
                          scans: _getScansInTimeRange(),
                        ),

                        const SizedBox(height: 24),

                        // Art generation stats
                        _ArtGenerationStats(
                          scans: _getScansInTimeRange(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<ScanHistoryEntry> _getScansInTimeRange() {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_timeRange) {
      case TimeRange.week:
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.threeMonths:
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case TimeRange.year:
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
      case TimeRange.all:
        return _scans;
    }

    return _scans.where((s) => s.timestamp.isAfter(cutoffDate)).toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showUpgradeDialog() {
    FeatureGate.showProDialog(
      context: context,
      feature: ProFeature.advancedAnalytics,
    );
  }

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }
}

class _OverviewSection extends StatelessWidget {
  final HistoryStatistics statistics;
  final List<ScanHistoryEntry> scans;

  const _OverviewSection({
    required this.statistics,
    required this.scans,
  });

  @override
  Widget build(BuildContext context) {
    final avgQuality = scans.isEmpty
        ? 0.0
        : scans.fold<double>(0, (sum, s) => sum + s.metadata.qualityScore) /
            scans.length;
    final totalInsights = scans.fold<int>(0, (sum, s) => sum + s.totalInsights);
    final scansWithArt =
        scans.where((s) => s.hasArtGenerations).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.camera_alt,
                label: 'Scans',
                value: scans.length.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.insights,
                label: 'Insights',
                value: totalInsights.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.star,
                label: 'Avg Quality',
                value: '${(avgQuality * 100).toInt()}%',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.auto_awesome,
                label: 'Art Pieces',
                value: scansWithArt.toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityTrendChart extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _QualityTrendChart({required this.scans});

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quality Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _LineChartPainter(
                      scans: scans,
                      getValue: (scan) => scan.metadata.qualityScore,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(scans.last.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatDate(scans.first.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

class _InsightsTrendChart extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _InsightsTrendChart({required this.scans});

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights Over Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _BarChartPainter(
                  scans: scans,
                  getValue: (scan) => scan.totalInsights.toDouble(),
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BodySystemsBreakdown extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _BodySystemsBreakdown({required this.scans});

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) return const SizedBox.shrink();

    final systemCounts = <String, int>{};
    for (var scan in scans) {
      for (var system in scan.allBodySystems) {
        systemCounts[system] = (systemCounts[system] ?? 0) + 1;
      }
    }

    final sortedSystems = systemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body Systems Analyzed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sortedSystems
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SystemBar(
                        system: entry.key,
                        count: entry.value,
                        maxCount: sortedSystems.first.value,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemBar extends StatelessWidget {
  final String system;
  final int count;
  final int maxCount;

  const _SystemBar({
    required this.system,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = count / maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              system,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          minHeight: 8,
        ),
      ],
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _ActivityHeatmap({required this.scans});

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Pattern',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Scans by day of week',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _DayOfWeekChart(scans: scans),
          ),
        ),
      ],
    );
  }
}

class _DayOfWeekChart extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _DayOfWeekChart({required this.scans});

  @override
  Widget build(BuildContext context) {
    final dayCounts = <int, int>{};
    for (var i = 1; i <= 7; i++) {
      dayCounts[i] = 0;
    }

    for (var scan in scans) {
      final day = scan.timestamp.weekday;
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
    }

    final maxCount = dayCounts.values.reduce(math.max);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final day = index + 1;
        final count = dayCounts[day] ?? 0;
        final height = maxCount > 0 ? (count / maxCount) * 100 : 0.0;

        return Column(
          children: [
            Container(
              width: 30,
              height: 100,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: const TextStyle(fontSize: 11),
            ),
          ],
        );
      }),
    );
  }
}

class _ArtGenerationStats extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _ArtGenerationStats({required this.scans});

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) return const SizedBox.shrink();

    final scansWithArt = scans.where((s) => s.hasArtGenerations).length;
    final percentage =
        scans.isEmpty ? 0.0 : (scansWithArt / scans.length) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Art Generation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'of scans have generated art',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$scansWithArt out of ${scans.length} scans',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.purple,
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.auto_awesome,
                          size: 40,
                          color: Colors.purple.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAnalyticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Analytics Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete more scans to see your wellness analytics and trends.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painters

class _LineChartPainter extends CustomPainter {
  final List<ScanHistoryEntry> scans;
  final double Function(ScanHistoryEntry) getValue;
  final Color color;

  _LineChartPainter({
    required this.scans,
    required this.getValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scans.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final sortedScans = List<ScanHistoryEntry>.from(scans)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final path = Path();
    for (var i = 0; i < sortedScans.length; i++) {
      final x = (i / (sortedScans.length - 1)) * size.width;
      final value = getValue(sortedScans[i]);
      final y = size.height - (value * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < sortedScans.length; i++) {
      final x = (i / (sortedScans.length - 1)) * size.width;
      final value = getValue(sortedScans[i]);
      final y = size.height - (value * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => false;
}

class _BarChartPainter extends CustomPainter {
  final List<ScanHistoryEntry> scans;
  final double Function(ScanHistoryEntry) getValue;
  final Color color;

  _BarChartPainter({
    required this.scans,
    required this.getValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scans.isEmpty) return;

    final sortedScans = List<ScanHistoryEntry>.from(scans)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final maxValue = sortedScans.map(getValue).reduce(math.max);
    if (maxValue == 0) return;

    final barWidth = size.width / sortedScans.length * 0.8;
    final spacing = size.width / sortedScans.length * 0.2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < sortedScans.length; i++) {
      final value = getValue(sortedScans[i]);
      final height = (value / maxValue) * size.height;
      final x = i * (barWidth + spacing) + spacing / 2;
      final y = size.height - height;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) => false;
}

/// View shown when analytics is locked for free users
class _LockedAnalyticsView extends StatelessWidget {
  final VoidCallback onUpgrade;

  const _LockedAnalyticsView({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Advanced Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track your wellness journey with detailed insights and trends over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Pro Feature',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.trending_up,
                    text: 'Quality trends over time',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.bar_chart,
                    text: 'Insights frequency analysis',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.pie_chart,
                    text: 'Body systems breakdown',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.calendar_today,
                    text: 'Activity heatmap by day',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.filter_alt,
                    text: 'Custom time range filtering',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Pro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start your 7-day free trial today',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feature item for locked view
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.amber.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
      ],
    );
  }
}

enum TimeRange {
  week,
  month,
  threeMonths,
  year,
  all,
}
