// lib/features/camera/presentation/screens/iris_result_screen.dart
// Screen displaying captured iris images and quality metrics

import 'package:flutter/material.dart';
import '../../domain/entities/iris_capture_result.dart';
import '../../../iris_analysis/data/services/iridology_mapping_service.dart';
import '../../../iris_analysis/presentation/screens/wellness_insights_screen.dart';
import '../../../art_generation/presentation/screens/art_style_selector_screen.dart';

/// Screen to display iris capture results
class IrisResultScreen extends StatelessWidget {
  final IrisCaptureResult result;

  const IrisResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iris Capture Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Accept & Continue',
            onPressed: () => _acceptAndContinue(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quality score card
            _QualityScoreCard(result: result),

            const SizedBox(height: 24),

            // Iris images
            const Text(
              'Captured Iris Images',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Left iris
                Expanded(
                  child: _IrisImageCard(
                    title: 'Left Iris',
                    imageBytes: result.leftIrisImage,
                  ),
                ),
                const SizedBox(width: 16),

                // Right iris
                Expanded(
                  child: _IrisImageCard(
                    title: 'Right Iris',
                    imageBytes: result.rightIrisImage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quality metrics details
            if (result.qualityMetrics != null) ...[
              const Text(
                'Quality Metrics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _QualityMetricsDetail(metrics: result.qualityMetrics!),
            ],

            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _acceptAndContinue(context),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Analysis'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToArtGeneration(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Create Art'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Retake Photo'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptAndContinue(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing iris patterns...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Perform iridology analysis on left iris
      final mappingService = IridologyMappingService();
      final analysis = await mappingService.analyzeIris(
        irisImageBytes: result.leftIrisImage!,
        isLeftEye: true,
      );

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to wellness insights screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WellnessInsightsScreen(
            analysis: analysis,
            irisImageBytes: result.leftIrisImage,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToArtGeneration(BuildContext context) {
    if (result.leftIrisImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No iris image available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtStyleSelectorScreen(
          irisImage: result.leftIrisImage!,
          isPro: false, // TODO: Load from user subscription status
        ),
      ),
    );
  }
}

class _QualityScoreCard extends StatelessWidget {
  final IrisCaptureResult result;

  const _QualityScoreCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final scorePercentage = (result.qualityScore * 100).toInt();
    final color = _getQualityColor(result.qualityScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quality Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.qualityRating,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: result.qualityScore,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '$scorePercentage%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class _IrisImageCard extends StatelessWidget {
  final String title;
  final dynamic imageBytes;

  const _IrisImageCard({
    required this.title,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (imageBytes != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 150,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 48),
              ),
            ),
        ],
      ),
    );
  }
}

class _QualityMetricsDetail extends StatelessWidget {
  final IrisQualityMetrics metrics;

  const _QualityMetricsDetail({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MetricRow(
              label: 'Sharpness',
              value: metrics.sharpness,
              icon: Icons.blur_off,
            ),
            _MetricRow(
              label: 'Brightness',
              value: metrics.brightness,
              icon: Icons.brightness_6,
            ),
            _MetricRow(
              label: 'Contrast',
              value: metrics.contrast,
              icon: Icons.contrast,
            ),
            _MetricRow(
              label: 'Size',
              value: metrics.irisSize,
              icon: Icons.aspect_ratio,
            ),
            _MetricRow(
              label: 'Alignment',
              value: metrics.centerAlignment,
              icon: Icons.center_focus_strong,
            ),
            const Divider(height: 24),
            _StatusRow(
              label: 'Glare Detection',
              isGood: !metrics.hasGlare,
            ),
            _StatusRow(
              label: 'Motion Blur',
              isGood: !metrics.hasMotionBlur,
            ),
            _StatusRow(
              label: 'Lighting',
              isGood: metrics.isWellLit,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toInt();
    final color = value >= 0.7 ? Colors.green : (value >= 0.5 ? Colors.orange : Colors.red);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isGood;

  const _StatusRow({
    required this.label,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.warning,
                size: 20,
                color: isGood ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                isGood ? 'Good' : 'Detected',
                style: TextStyle(
                  color: isGood ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
