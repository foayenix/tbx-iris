// lib/features/iris_analysis/data/services/iris_segmentation_service.dart
// Service for segmenting iris into iridology zones using polar coordinates

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../../../../core/constants/iridology_zones.dart';

/// Service for segmenting iris image into zones
class IrisSegmentationService {
  /// Extract pixels for a specific iridology zone
  Future<List<img.Pixel>> extractZonePixels({
    required img.Image irisImage,
    required IridologyZone zone,
  }) async {
    final pixels = <img.Pixel>[];

    final centerX = irisImage.width / 2;
    final centerY = irisImage.height / 2;
    final maxRadius = math.min(centerX, centerY);

    // Iterate through image pixels
    for (int y = 0; y < irisImage.height; y++) {
      for (int x = 0; x < irisImage.width; x++) {
        // Convert to polar coordinates
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = math.sqrt(dx * dx + dy * dy);
        final angle = math.atan2(dy, dx);

        // Normalize distance (0.0 to 1.0)
        final normalizedDistance = distance / maxRadius;

        // Normalize angle to 0-2π range
        final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;

        // Check if this pixel is within the zone
        if (zone.containsPoint(normalizedAngle, normalizedDistance)) {
          pixels.add(irisImage.getPixel(x, y));
        }
      }
    }

    return pixels;
  }

  /// Create a mask image for a specific zone
  Future<img.Image> createZoneMask({
    required int width,
    required int height,
    required IridologyZone zone,
  }) async {
    final mask = img.Image(width: width, height: height);

    final centerX = width / 2;
    final centerY = height / 2;
    final maxRadius = math.min(centerX, centerY);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = math.sqrt(dx * dx + dy * dy);
        final angle = math.atan2(dy, dx);

        final normalizedDistance = distance / maxRadius;
        final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;

        if (zone.containsPoint(normalizedAngle, normalizedDistance)) {
          // White for zone area
          mask.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          // Black for outside zone
          mask.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return mask;
  }

  /// Extract sub-image for a specific zone with bounding box
  Future<img.Image?> extractZoneImage({
    required img.Image irisImage,
    required IridologyZone zone,
  }) async {
    try {
      // Calculate bounding box for zone
      final bounds = _calculateZoneBounds(
        irisImage.width,
        irisImage.height,
        zone,
      );

      if (bounds == null) return null;

      // Crop to bounding box
      final cropped = img.copyCrop(
        irisImage,
        x: bounds.left,
        y: bounds.top,
        width: bounds.width,
        height: bounds.height,
      );

      return cropped;
    } catch (e) {
      print('Error extracting zone image: $e');
      return null;
    }
  }

  /// Calculate bounding box for a zone
  ZoneBounds? _calculateZoneBounds(
    int imageWidth,
    int imageHeight,
    IridologyZone zone,
  ) {
    final centerX = imageWidth / 2;
    final centerY = imageHeight / 2;
    final maxRadius = math.min(centerX, centerY);

    // Calculate bounds based on zone's angular and radial extent
    final innerRadius = zone.innerRadius * maxRadius;
    final outerRadius = zone.outerRadius * maxRadius;

    // Sample points along zone boundaries to find min/max x,y
    double minX = imageWidth.toDouble();
    double maxX = 0.0;
    double minY = imageHeight.toDouble();
    double maxY = 0.0;

    // Sample multiple points around the zone
    const numSamples = 20;
    for (int i = 0; i < numSamples; i++) {
      final angle = zone.startAngle +
          (zone.endAngle - zone.startAngle) * i / numSamples;

      // Check points at inner and outer radius
      for (final radius in [innerRadius, outerRadius]) {
        final x = centerX + radius * math.cos(angle);
        final y = centerY + radius * math.sin(angle);

        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }

    // Add padding
    const padding = 5;
    minX = (minX - padding).clamp(0, imageWidth - 1);
    maxX = (maxX + padding).clamp(0, imageWidth - 1);
    minY = (minY - padding).clamp(0, imageHeight - 1);
    maxY = (maxY + padding).clamp(0, imageHeight - 1);

    final width = (maxX - minX).toInt();
    final height = (maxY - minY).toInt();

    if (width <= 0 || height <= 0) return null;

    return ZoneBounds(
      left: minX.toInt(),
      top: minY.toInt(),
      width: width,
      height: height,
    );
  }

  /// Map all zones for an iris
  Future<Map<String, List<img.Pixel>>> mapAllZones({
    required img.Image irisImage,
    required bool isLeftEye,
  }) async {
    final zonePixels = <String, List<img.Pixel>>{};
    final zones = IridologyZones.getZonesForEye(isLeftEye);

    for (final zone in zones) {
      final pixels = await extractZonePixels(
        irisImage: irisImage,
        zone: zone,
      );
      zonePixels[zone.id] = pixels;
    }

    return zonePixels;
  }

  /// Create visualization of all zones
  Future<img.Image> visualizeZones({
    required img.Image irisImage,
    required bool isLeftEye,
  }) async {
    final visualization = img.Image.from(irisImage);
    final zones = IridologyZones.getZonesForEye(isLeftEye);

    // Color palette for different body systems
    final systemColors = {
      'Digestive': [255, 100, 100],
      'Respiratory': [100, 150, 255],
      'Cardiovascular': [255, 50, 50],
      'Nervous': [200, 100, 255],
      'Urinary': [100, 200, 255],
      'Immune': [100, 255, 100],
      'Endocrine': [255, 200, 100],
    };

    final centerX = visualization.width / 2;
    final centerY = visualization.height / 2;
    final maxRadius = math.min(centerX, centerY);

    // Draw zone overlays
    for (final zone in zones) {
      final color = systemColors[zone.bodySystem] ?? [200, 200, 200];

      // Draw zone outline
      for (int y = 0; y < visualization.height; y++) {
        for (int x = 0; x < visualization.width; x++) {
          final dx = x - centerX;
          final dy = y - centerY;
          final distance = math.sqrt(dx * dx + dy * dy);
          final angle = math.atan2(dy, dx);

          final normalizedDistance = distance / maxRadius;
          final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;

          if (zone.containsPoint(normalizedAngle, normalizedDistance)) {
            // Blend zone color with original
            final original = visualization.getPixel(x, y);
            final blendedR = ((original.r + color[0]) / 2).toInt();
            final blendedG = ((original.g + color[1]) / 2).toInt();
            final blendedB = ((original.b + color[2]) / 2).toInt();

            visualization.setPixelRgba(
              x,
              y,
              blendedR,
              blendedG,
              blendedB,
              200, // Semi-transparent
            );
          }
        }
      }
    }

    return visualization;
  }

  /// Get center point of a zone
  ZoneCenter getZoneCenter({
    required int imageWidth,
    required int imageHeight,
    required IridologyZone zone,
  }) {
    final centerX = imageWidth / 2;
    final centerY = imageHeight / 2;
    final maxRadius = math.min(centerX, centerY);

    // Calculate average radius and angle for zone center
    final avgRadius = (zone.innerRadius + zone.outerRadius) / 2 * maxRadius;
    final avgAngle = (zone.startAngle + zone.endAngle) / 2;

    final x = centerX + avgRadius * math.cos(avgAngle);
    final y = centerY + avgRadius * math.sin(avgAngle);

    return ZoneCenter(x: x, y: y);
  }
}

/// Bounding box for a zone
class ZoneBounds {
  final int left;
  final int top;
  final int width;
  final int height;

  const ZoneBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// Center point of a zone
class ZoneCenter {
  final double x;
  final double y;

  const ZoneCenter({required this.x, required this.y});
}
