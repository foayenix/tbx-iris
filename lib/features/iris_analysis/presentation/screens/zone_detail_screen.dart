// lib/features/iris_analysis/presentation/screens/zone_detail_screen.dart
// Detailed view of a specific iris zone with analysis

import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../../core/constants/iridology_zones.dart';
import '../../domain/entities/iridology_analysis.dart';

/// Screen showing detailed information about a specific zone
class ZoneDetailScreen extends StatelessWidget {
  final IridologyZone zone;
  final ZoneAnalysis? analysis;
  final Uint8List irisImage;
  final bool isLeftEye;

  const ZoneDetailScreen({
    super.key,
    required this.zone,
    this.analysis,
    required this.irisImage,
    required this.isLeftEye,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(zone.bodySystem),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showZoneInfo(context),
            tooltip: 'Zone Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone visualization
            _ZoneVisualization(
              zone: zone,
              irisImage: irisImage,
              isLeftEye: isLeftEye,
            ),

            // Analysis section
            if (analysis != null) ...[
              _AnalysisSection(analysis: analysis!),
            ] else
              _NoAnalysisCard(),

            // Wellness reflections
            _WellnessReflectionsSection(zone: zone),

            // Zone technical details
            _TechnicalDetailsSection(zone: zone),
          ],
        ),
      ),
    );
  }

  void _showZoneInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(zone.bodySystem),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'About This Zone',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This iris zone is traditionally associated with the ${zone.bodySystem.toLowerCase()} system in iridology.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Iridology is not a medical diagnostic tool. This information is for wellness education and reflection only.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ZoneVisualization extends StatelessWidget {
  final IridologyZone zone;
  final Uint8List irisImage;
  final bool isLeftEye;

  const _ZoneVisualization({
    required this.zone,
    required this.irisImage,
    required this.isLeftEye,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Iris image with zone highlight
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipOval(
                  child: Image.memory(
                    irisImage,
                    fit: BoxFit.cover,
                  ),
                ),
                // Zone overlay would be drawn here
                // For simplicity, showing a semi-transparent overlay
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getZoneColor(zone),
                      width: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            zone.bodySystem,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Color _getZoneColor(IridologyZone zone) {
    switch (zone.bodySystem.toLowerCase()) {
      case 'digestive':
        return Colors.orange;
      case 'respiratory':
        return Colors.lightBlue;
      case 'cardiovascular':
        return Colors.red;
      case 'nervous':
        return Colors.purple;
      case 'urinary':
        return Colors.cyan;
      case 'immune':
        return Colors.green;
      case 'endocrine':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }
}

class _AnalysisSection extends StatelessWidget {
  final ZoneAnalysis analysis;

  const _AnalysisSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Significance score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Significance Score',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: analysis.significanceScore,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getSignificanceColor(analysis.significanceScore),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(analysis.significanceScore * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSignificanceDescription(analysis.significanceScore),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Color profile
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ColorIndicator(
                        label: 'Red',
                        value: analysis.colorProfile.red,
                        color: Colors.red,
                      ),
                      _ColorIndicator(
                        label: 'Green',
                        value: analysis.colorProfile.green,
                        color: Colors.green,
                      ),
                      _ColorIndicator(
                        label: 'Blue',
                        value: analysis.colorProfile.blue,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricIndicator(
                        label: 'Brightness',
                        value: analysis.colorProfile.brightness,
                        icon: Icons.brightness_high,
                      ),
                      _MetricIndicator(
                        label: 'Saturation',
                        value: analysis.colorProfile.saturation,
                        icon: Icons.palette,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Texture features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Texture Features',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TextureRow(
                    label: 'Uniformity',
                    value: analysis.textureFeatures.uniformity,
                  ),
                  const SizedBox(height: 8),
                  _TextureRow(
                    label: 'Density',
                    value: analysis.textureFeatures.density,
                  ),
                  const SizedBox(height: 8),
                  _TextureRow(
                    label: 'Pattern Strength',
                    value: analysis.textureFeatures.patternStrength,
                  ),
                ],
              ),
            ),
          ),

          // Observations
          if (analysis.observations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observations',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...analysis.observations.map(
                      (obs) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(obs)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSignificanceColor(double score) {
    if (score < 0.33) return Colors.green;
    if (score < 0.66) return Colors.orange;
    return Colors.red;
  }

  String _getSignificanceDescription(double score) {
    if (score < 0.33) {
      return 'Low significance - No notable characteristics detected';
    } else if (score < 0.66) {
      return 'Moderate significance - Some characteristics of interest';
    } else {
      return 'High significance - Notable characteristics detected';
    }
  }
}

class _ColorIndicator extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ColorIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(value),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

class _MetricIndicator extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _MetricIndicator({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _TextureRow extends StatelessWidget {
  final String label;
  final double value;

  const _TextureRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade200,
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _NoAnalysisCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No Analysis Available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analysis data is not available for this zone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WellnessReflectionsSection extends StatelessWidget {
  final IridologyZone zone;

  const _WellnessReflectionsSection({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wellness Reflections',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...zone.wellnessReflections.map(
                    (reflection) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              reflection,
                              style: const TextStyle(fontSize: 15),
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
        ],
      ),
    );
  }
}

class _TechnicalDetailsSection extends StatelessWidget {
  final IridologyZone zone;

  const _TechnicalDetailsSection({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: const Text(
          'Technical Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('Zone ID', zone.id),
                _DetailRow('Body System', zone.bodySystem),
                _DetailRow(
                  'Angular Range',
                  '${(zone.startAngle * 180 / 3.14159).toStringAsFixed(0)}° - '
                      '${(zone.endAngle * 180 / 3.14159).toStringAsFixed(0)}°',
                ),
                _DetailRow(
                  'Radial Range',
                  '${(zone.innerRadius * 100).toStringAsFixed(0)}% - '
                      '${(zone.outerRadius * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
