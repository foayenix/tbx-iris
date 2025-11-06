// lib/features/history/presentation/screens/scan_comparison_screen.dart
// Screen for comparing multiple scans side-by-side

import 'package:flutter/material.dart';

import '../../domain/entities/scan_history_entry.dart';

/// Screen for comparing 2-3 scans side-by-side
class ScanComparisonScreen extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const ScanComparisonScreen({
    super.key,
    required this.scans,
  }) : assert(scans.length >= 2 && scans.length <= 3,
            'Must compare 2-3 scans');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Scans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showComparisonInfo(context),
            tooltip: 'About Comparison',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan headers
            _ScanHeaders(scans: scans),

            // Iris images comparison
            _IrisImagesComparison(scans: scans),

            // Quality metrics comparison
            _QualityMetricsComparison(scans: scans),

            // Insights comparison
            _InsightsComparison(scans: scans),

            // Body systems comparison
            _BodySystemsComparison(scans: scans),

            // Timeline chart
            _TimelineChart(scans: scans),
          ],
        ),
      ),
    );
  }

  void _showComparisonInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Comparison'),
        content: const Text(
          'This view allows you to compare multiple scans side-by-side to track '
          'changes over time. You can see differences in quality, insights, and '
          'body systems analyzed.\n\n'
          'Note: This is for tracking wellness education, not medical diagnosis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}

class _ScanHeaders extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _ScanHeaders({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: scans
            .map(
              (scan) => Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDate(scan.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(scan.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _IrisImagesComparison extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _IrisImagesComparison({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Iris Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: scans
                .map(
                  (scan) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: ClipOval(
                          child: Image.memory(
                            scan.leftIrisImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QualityMetricsComparison extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _QualityMetricsComparison({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quality Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: scans
                    .map(
                      (scan) => Expanded(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              value: scan.metadata.qualityScore,
                              strokeWidth: 6,
                              backgroundColor: Colors.grey.shade200,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(scan.metadata.qualityScore * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              _TrendIndicator(
                values: scans
                    .map((s) => s.metadata.qualityScore)
                    .toList(),
                label: 'Quality Trend',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsComparison extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _InsightsComparison({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insights Count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: scans
                    .map(
                      (scan) => Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  scan.totalInsights.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'insights',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              _TrendIndicator(
                values:
                    scans.map((s) => s.totalInsights.toDouble()).toList(),
                label: 'Insights Trend',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodySystemsComparison extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _BodySystemsComparison({required this.scans});

  @override
  Widget build(BuildContext context) {
    // Get all unique body systems across all scans
    final allSystems = <String>{};
    for (var scan in scans) {
      allSystems.addAll(scan.allBodySystems);
    }

    if (allSystems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Body Systems Analyzed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...allSystems.map(
                (system) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          system,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...scans.map(
                        (scan) => Expanded(
                          child: Center(
                            child: scan.allBodySystems.contains(system)
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineChart extends StatelessWidget {
  final List<ScanHistoryEntry> scans;

  const _TimelineChart({required this.scans});

  @override
  Widget build(BuildContext context) {
    // Sort scans by date
    final sortedScans = List<ScanHistoryEntry>.from(scans)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: CustomPaint(
                  size: const Size(double.infinity, 100),
                  painter: _TimelineChartPainter(scans: sortedScans),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(sortedScans.first.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _formatDate(sortedScans.last.timestamp),
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
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _TimelineChartPainter extends CustomPainter {
  final List<ScanHistoryEntry> scans;

  _TimelineChartPainter({required this.scans});

  @override
  void paint(Canvas canvas, Size size) {
    if (scans.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Calculate positions
    final firstTime = scans.first.timestamp.millisecondsSinceEpoch.toDouble();
    final lastTime = scans.last.timestamp.millisecondsSinceEpoch.toDouble();
    final timeRange = lastTime - firstTime;

    final points = <Offset>[];
    for (var i = 0; i < scans.length; i++) {
      final scan = scans[i];
      final x = timeRange == 0
          ? size.width / 2
          : (scan.timestamp.millisecondsSinceEpoch - firstTime) /
              timeRange *
              size.width;
      final y = size.height - (scan.metadata.qualityScore * size.height);
      points.add(Offset(x, y));
    }

    // Draw line
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw points
    for (var point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_TimelineChartPainter oldDelegate) => false;
}

class _TrendIndicator extends StatelessWidget {
  final List<double> values;
  final String label;

  const _TrendIndicator({
    required this.values,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return const SizedBox.shrink();
    }

    final trend = values.last - values.first;
    final isPositive = trend > 0;
    final isNeutral = trend.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isNeutral
            ? Colors.grey.shade200
            : (isPositive
                ? Colors.green.shade50
                : Colors.red.shade50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNeutral
                ? Icons.trending_flat
                : (isPositive ? Icons.trending_up : Icons.trending_down),
            size: 16,
            color: isNeutral
                ? Colors.grey.shade600
                : (isPositive ? Colors.green.shade700 : Colors.red.shade700),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isNeutral
                  ? Colors.grey.shade700
                  : (isPositive
                      ? Colors.green.shade700
                      : Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
