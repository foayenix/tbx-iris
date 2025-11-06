// lib/features/iris_analysis/presentation/widgets/interactive_iris_map.dart
// Interactive widget displaying iris with zone overlays

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/iridology_zones.dart';
import '../../domain/entities/iridology_analysis.dart';

/// Interactive iris map with zone overlays
class InteractiveIrisMap extends StatefulWidget {
  final Uint8List irisImage;
  final IridologyAnalysis? analysis;
  final bool isLeftEye;
  final Function(IridologyZone zone, ZoneAnalysis? analysis)? onZoneTap;
  final bool showLabels;
  final bool showHeatmap;

  const InteractiveIrisMap({
    super.key,
    required this.irisImage,
    this.analysis,
    required this.isLeftEye,
    this.onZoneTap,
    this.showLabels = true,
    this.showHeatmap = false,
  });

  @override
  State<InteractiveIrisMap> createState() => _InteractiveIrisMapState();
}

class _InteractiveIrisMapState extends State<InteractiveIrisMap> {
  IridologyZone? _selectedZone;
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map display
        AspectRatio(
          aspectRatio: 1.0,
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Iris image
                ClipOval(
                  child: Image.memory(
                    widget.irisImage,
                    fit: BoxFit.cover,
                  ),
                ),

                // Zone overlays
                CustomPaint(
                  painter: IrisZonePainter(
                    zones: IridologyZones.getZonesForEye(widget.isLeftEye),
                    selectedZone: _selectedZone,
                    analysis: widget.analysis,
                    showLabels: widget.showLabels,
                    showHeatmap: widget.showHeatmap,
                  ),
                ),

                // Tap indicator
                if (_tapPosition != null)
                  Positioned(
                    left: _tapPosition!.dx - 10,
                    top: _tapPosition!.dy - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Selected zone info
        if (_selectedZone != null) ...[
          const SizedBox(height: 16),
          _SelectedZoneCard(
            zone: _selectedZone!,
            analysis: widget.analysis?.getZoneAnalysis(_selectedZone!.id),
            onClose: () => setState(() => _selectedZone = null),
            onViewDetails: () {
              if (widget.onZoneTap != null) {
                widget.onZoneTap!(
                  _selectedZone!,
                  widget.analysis?.getZoneAnalysis(_selectedZone!.id),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  void _handleTap(Offset localPosition) {
    // Get the render box to calculate relative position
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;

    // Calculate center and radius
    final center = Offset(size.width / 2, size.width / 2);
    final radius = size.width / 2;

    // Calculate relative position from center
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Calculate distance from center
    final distance = math.sqrt(dx * dx + dy * dy);
    final normalizedDistance = distance / radius;

    // Calculate angle (0 to 2π)
    var angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    // Find which zone was tapped
    final zones = IridologyZones.getZonesForEye(widget.isLeftEye);
    for (var zone in zones) {
      if (zone.containsPoint(angle, normalizedDistance)) {
        setState(() {
          _selectedZone = zone;
          _tapPosition = localPosition;
        });
        return;
      }
    }

    // Tapped outside zones
    setState(() {
      _selectedZone = null;
      _tapPosition = null;
    });
  }
}

/// Custom painter for iris zones
class IrisZonePainter extends CustomPainter {
  final List<IridologyZone> zones;
  final IridologyZone? selectedZone;
  final IridologyAnalysis? analysis;
  final bool showLabels;
  final bool showHeatmap;

  IrisZonePainter({
    required this.zones,
    this.selectedZone,
    this.analysis,
    required this.showLabels,
    required this.showHeatmap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var zone in zones) {
      final isSelected = selectedZone?.id == zone.id;
      final zoneAnalysis = analysis?.getZoneAnalysis(zone.id);

      // Draw zone overlay
      _drawZone(
        canvas,
        center,
        radius,
        zone,
        isSelected: isSelected,
        zoneAnalysis: zoneAnalysis,
      );

      // Draw label if enabled
      if (showLabels && !isSelected) {
        _drawLabel(canvas, center, radius, zone);
      }
    }

    // Draw selected zone on top
    if (selectedZone != null) {
      final zoneAnalysis = analysis?.getZoneAnalysis(selectedZone!.id);
      _drawZone(
        canvas,
        center,
        radius,
        selectedZone!,
        isSelected: true,
        zoneAnalysis: zoneAnalysis,
      );

      if (showLabels) {
        _drawLabel(canvas, center, radius, selectedZone!, highlight: true);
      }
    }
  }

  void _drawZone(
    Canvas canvas,
    Offset center,
    double radius,
    IridologyZone zone, {
    required bool isSelected,
    ZoneAnalysis? zoneAnalysis,
  }) {
    final path = Path();

    // Calculate zone boundaries
    final innerRadius = radius * zone.innerRadius;
    final outerRadius = radius * zone.outerRadius;
    final startAngle = zone.startAngle;
    final sweepAngle = zone.endAngle - zone.startAngle;

    // Create arc path
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
    );

    // Line to inner arc
    final endX = center.dx + outerRadius * math.cos(zone.endAngle);
    final endY = center.dy + outerRadius * math.sin(zone.endAngle);
    path.lineTo(endX, endY);

    // Inner arc (reverse)
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      zone.endAngle,
      -sweepAngle,
      false,
    );

    path.close();

    // Determine color based on mode
    Color fillColor;
    if (showHeatmap && zoneAnalysis != null) {
      // Heatmap color based on significance
      fillColor = _getHeatmapColor(zoneAnalysis.significanceScore);
    } else if (isSelected) {
      fillColor = Colors.blue.withOpacity(0.4);
    } else {
      fillColor = _getZoneColor(zone).withOpacity(0.15);
    }

    // Draw fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = isSelected
          ? Colors.blue.withOpacity(0.8)
          : Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.0;
    canvas.drawPath(path, borderPaint);
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    IridologyZone zone, {
    bool highlight = false,
  }) {
    // Calculate label position (middle of zone)
    final midAngle = (zone.startAngle + zone.endAngle) / 2;
    final midRadius = (zone.innerRadius + zone.outerRadius) / 2;
    final labelRadius = radius * midRadius;

    final labelX = center.dx + labelRadius * math.cos(midAngle);
    final labelY = center.dy + labelRadius * math.sin(midAngle);

    // Draw label background
    final bgPaint = Paint()
      ..color = highlight
          ? Colors.blue.withOpacity(0.9)
          : Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(labelX, labelY),
      highlight ? 12 : 8,
      bgPaint,
    );

    // Draw label text (abbreviated)
    final textSpan = TextSpan(
      text: _getAbbreviation(zone.bodySystem),
      style: TextStyle(
        color: Colors.white,
        fontSize: highlight ? 10 : 8,
        fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        labelX - textPainter.width / 2,
        labelY - textPainter.height / 2,
      ),
    );
  }

  Color _getZoneColor(IridologyZone zone) {
    // Color code by body system
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
      case 'musculoskeletal':
        return Colors.brown;
      case 'reproductive':
        return Colors.pink;
      case 'lymphatic':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getHeatmapColor(double significance) {
    // Green (low) -> Yellow (medium) -> Red (high)
    if (significance < 0.33) {
      return Colors.green.withOpacity(0.4);
    } else if (significance < 0.66) {
      return Colors.yellow.withOpacity(0.4);
    } else {
      return Colors.red.withOpacity(0.4);
    }
  }

  String _getAbbreviation(String bodySystem) {
    // Return 2-3 letter abbreviation
    switch (bodySystem.toLowerCase()) {
      case 'digestive':
        return 'DIG';
      case 'respiratory':
        return 'RSP';
      case 'cardiovascular':
        return 'CVS';
      case 'nervous':
        return 'NRV';
      case 'urinary':
        return 'URN';
      case 'immune':
        return 'IMM';
      case 'endocrine':
        return 'END';
      case 'musculoskeletal':
        return 'MSK';
      case 'reproductive':
        return 'REP';
      case 'lymphatic':
        return 'LYM';
      default:
        return bodySystem.substring(0, 3).toUpperCase();
    }
  }

  @override
  bool shouldRepaint(IrisZonePainter oldDelegate) {
    return oldDelegate.selectedZone != selectedZone ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.showHeatmap != showHeatmap;
  }
}

/// Card showing selected zone information
class _SelectedZoneCard extends StatelessWidget {
  final IridologyZone zone;
  final ZoneAnalysis? analysis;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _SelectedZoneCard({
    required this.zone,
    this.analysis,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    zone.bodySystem,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Analysis info
            if (analysis != null) ...[
              Row(
                children: [
                  const Text(
                    'Significance: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: analysis!.significanceScore,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSignificanceColor(analysis!.significanceScore),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(analysis!.significanceScore * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Zone description
            Text(
              'Area: ${((zone.endAngle - zone.startAngle) * 180 / math.pi).toStringAsFixed(0)}° arc',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),

            // View details button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSignificanceColor(double score) {
    if (score < 0.33) return Colors.green;
    if (score < 0.66) return Colors.orange;
    return Colors.red;
  }
}
