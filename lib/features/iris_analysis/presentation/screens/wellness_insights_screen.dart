// lib/features/iris_analysis/presentation/screens/wellness_insights_screen.dart
// Screen displaying wellness insights from iridology analysis

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/wellness_disclaimer.dart';
import '../../../../core/constants/iridology_zones.dart';
import '../../domain/entities/iridology_analysis.dart';
import '../../../art_generation/presentation/screens/art_style_selector_screen.dart';
import '../widgets/interactive_iris_map.dart';
import 'zone_detail_screen.dart';

/// Screen displaying wellness insights
class WellnessInsightsScreen extends StatefulWidget {
  final IridologyAnalysis analysis;
  final Uint8List? irisImageBytes;

  const WellnessInsightsScreen({
    super.key,
    required this.analysis,
    this.irisImageBytes,
  });

  @override
  State<WellnessInsightsScreen> createState() => _WellnessInsightsScreenState();
}

class _WellnessInsightsScreenState extends State<WellnessInsightsScreen> {
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Insights'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
            tooltip: _showMap ? 'Show List' : 'Show Map',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDisclaimerDialog(context),
            tooltip: 'View Disclaimer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Prominent disclaimer banner
          _DisclaimerBanner(),

          // Analysis summary
          _AnalysisSummary(analysis: widget.analysis),

          // Interactive Iris Map (if image available and map mode)
          if (widget.irisImageBytes != null && _showMap) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive Iris Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap zones to view detailed analysis',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InteractiveIrisMap(
                    irisImage: widget.irisImageBytes!,
                    analysis: widget.analysis,
                    isLeftEye: widget.analysis.isLeftEye,
                    onZoneTap: _onZoneTap,
                    showLabels: true,
                    showHeatmap: false,
                  ),
                ],
              ),
            ),
          ],

          // Art generation CTA if iris image is available
          if (widget.irisImageBytes != null && !_showMap)
            _ArtGenerationCTA(onTap: () => _navigateToArtGeneration(context)),

          // Insights list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.analysis.insights.length,
              itemBuilder: (context, index) {
                return _InsightCard(insight: widget.analysis.insights[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.irisImageBytes != null
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToArtGeneration(context),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Create Art'),
            )
          : null,
    );
  }

  void _onZoneTap(IridologyZone zone, ZoneAnalysis? analysis) {
    if (widget.irisImageBytes == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailScreen(
          zone: zone,
          analysis: analysis,
          irisImage: widget.irisImageBytes!,
          isLeftEye: widget.analysis.isLeftEye,
        ),
      ),
    );
  }

  void _navigateToArtGeneration(BuildContext context) {
    if (widget.irisImageBytes == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtStyleSelectorScreen(
          irisImage: widget.irisImageBytes!,
          isPro: false, // TODO: Load from user subscription status
        ),
      ),
    );
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Important Health Information'),
        content: const SingleChildScrollView(
          child: Text(WellnessDisclaimer.fullDisclaimer),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFFFF3E0), // Amber 50
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFFE65100), // Amber 900
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              WellnessDisclaimer.shortDisclaimer,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFE65100),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSummary extends StatelessWidget {
  final IridologyAnalysis analysis;

  const _AnalysisSummary({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              icon: Icons.remove_red_eye,
              label: 'Eye',
              value: analysis.isLeftEye ? 'Left' : 'Right',
            ),
            _SummaryRow(
              icon: Icons.palette,
              label: 'Iris Color',
              value: analysis.overallColorProfile.description,
            ),
            _SummaryRow(
              icon: Icons.insights,
              label: 'Insights Found',
              value: '${analysis.insights.length}',
            ),
            _SummaryRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: _formatDate(analysis.timestamp),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final WellnessInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(insight.category).withOpacity(0.2),
          child: Icon(
            _getCategoryIcon(insight.category),
            color: _getCategoryColor(insight.category),
            size: 20,
          ),
        ),
        title: Text(
          insight.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              insight.category.displayName,
              style: TextStyle(
                fontSize: 12,
                color: _getCategoryColor(insight.category),
              ),
            ),
            if (insight.isHighConfidence) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.stars, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '${insight.confidenceLevel} significance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.description,
                  style: const TextStyle(fontSize: 14),
                ),
                if (insight.reflectionPrompts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Reflection Prompts:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...insight.reflectionPrompts.map(
                    (prompt) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              prompt,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(InsightCategory category) {
    switch (category) {
      case InsightCategory.general:
        return Icons.health_and_safety;
      case InsightCategory.lifestyle:
        return Icons.self_improvement;
      case InsightCategory.nutrition:
        return Icons.restaurant;
      case InsightCategory.stress:
        return Icons.spa;
      case InsightCategory.activity:
        return Icons.directions_run;
      case InsightCategory.environmental:
        return Icons.eco;
    }
  }

  Color _getCategoryColor(InsightCategory category) {
    switch (category) {
      case InsightCategory.general:
        return Colors.blue;
      case InsightCategory.lifestyle:
        return Colors.purple;
      case InsightCategory.nutrition:
        return Colors.green;
      case InsightCategory.stress:
        return Colors.orange;
      case InsightCategory.activity:
        return Colors.red;
      case InsightCategory.environmental:
        return Colors.teal;
    }
  }
}

class _ArtGenerationCTA extends StatelessWidget {
  final VoidCallback onTap;

  const _ArtGenerationCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transform Your Iris',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create stunning AI art from your iris',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
