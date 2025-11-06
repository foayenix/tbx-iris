// lib/features/camera/presentation/widgets/iris_guide_overlay.dart
// Custom painted overlay with iris capture guide

import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/iris_capture_result.dart';

/// Overlay widget that draws the iris capture guide
class IrisGuideOverlay extends StatelessWidget {
  final CaptureGuidanceState guidanceState;

  const IrisGuideOverlay({
    super.key,
    required this.guidanceState,
  });

  Color get _guideColor {
    switch (guidanceState) {
      case CaptureGuidanceState.ready:
        return Colors.green;
      case CaptureGuidanceState.success:
        return Colors.green.shade400;
      case CaptureGuidanceState.processing:
        return Colors.blue;
      case CaptureGuidanceState.error:
      case CaptureGuidanceState.lowLight:
      case CaptureGuidanceState.glareDetected:
        return Colors.red;
      case CaptureGuidanceState.tooClose:
      case CaptureGuidanceState.tooFar:
      case CaptureGuidanceState.offCenter:
      case CaptureGuidanceState.motionBlur:
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IrisGuidePainter(guideColor: _guideColor),
    );
  }
}

class _IrisGuidePainter extends CustomPainter {
  final Color guideColor;

  _IrisGuidePainter({required this.guideColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Guide circle
    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw overlay with circle cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw animated guide circle
    canvas.drawCircle(center, radius, guidePaint);

    // Draw crosshair
    final crosshairPaint = Paint()
      ..color = guideColor.withOpacity(0.5)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(center.dx - 30, center.dy),
      Offset(center.dx + 30, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 30),
      Offset(center.dx, center.dy + 30),
      crosshairPaint,
    );

    // Draw corner markers for framing
    _drawCornerMarkers(canvas, center, radius, guidePaint);
  }

  void _drawCornerMarkers(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final markerLength = 15.0;
    final angles = [0, 90, 180, 270]; // degrees

    for (final angleDeg in angles) {
      final angleRad = angleDeg * pi / 180;
      final x = center.dx + radius * cos(angleRad);
      final y = center.dy + radius * sin(angleRad);

      // Draw small line extending outward
      final endX = center.dx + (radius + markerLength) * cos(angleRad);
      final endY = center.dy + (radius + markerLength) * sin(angleRad);

      canvas.drawLine(
        Offset(x, y),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_IrisGuidePainter oldDelegate) {
    return oldDelegate.guideColor != guideColor;
  }
}
