// lib/features/iris_analysis/data/services/color_analysis_service.dart
// Service for analyzing color characteristics of iris zones

import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../../domain/entities/iridology_analysis.dart';

/// Service for color analysis of iris regions
class ColorAnalysisService {
  /// Analyze color profile of a list of pixels
  Future<ColorProfile> analyzePixels(List<img.Pixel> pixels) async {
    if (pixels.isEmpty) {
      return const ColorProfile(
        red: 0,
        green: 0,
        blue: 0,
        brightness: 0,
        saturation: 0,
        dominantColor: IrisColorType.mixed,
      );
    }

    // Calculate average RGB values
    double totalR = 0, totalG = 0, totalB = 0;

    for (final pixel in pixels) {
      totalR += pixel.r;
      totalG += pixel.g;
      totalB += pixel.b;
    }

    final avgR = totalR / pixels.length / 255.0;
    final avgG = totalG / pixels.length / 255.0;
    final avgB = totalB / pixels.length / 255.0;

    // Calculate HSV values
    final hsv = _rgbToHsv(avgR, avgG, avgB);
    final brightness = hsv['v']!;
    final saturation = hsv['s']!;

    // Determine dominant color
    final dominantColor = _classifyColor(avgR, avgG, avgB, hsv['h']!);

    // Find secondary colors
    final secondaryColors = _findSecondaryColors(pixels);

    return ColorProfile(
      red: avgR,
      green: avgG,
      blue: avgB,
      brightness: brightness,
      saturation: saturation,
      dominantColor: dominantColor,
      secondaryColors: secondaryColors,
    );
  }

  /// Analyze overall iris color profile
  Future<IrisColorProfile> analyzeOverallColor(
    img.Image irisImage,
  ) async {
    final allPixels = <img.Pixel>[];

    // Sample pixels from iris (skip edges)
    final centerX = irisImage.width / 2;
    final centerY = irisImage.height / 2;
    final radius = math.min(centerX, centerY) * 0.8;

    for (int y = 0; y < irisImage.height; y++) {
      for (int x = 0; x < irisImage.width; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < radius) {
          allPixels.add(irisImage.getPixel(x, y));
        }
      }
    }

    final colorProfile = await analyzePixels(allPixels);

    // Calculate color variation
    final variation = _calculateColorVariation(allPixels);

    // Detect distinct zones
    final hasDistinctZones = variation > 0.3;

    return IrisColorProfile(
      primaryColor: colorProfile.dominantColor,
      secondaryColors: colorProfile.secondaryColors,
      colorVariation: variation,
      hasDistinctZones: hasDistinctZones,
    );
  }

  /// Convert RGB to HSV
  Map<String, double> _rgbToHsv(double r, double g, double b) {
    final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
    final minC = [r, g, b].reduce((a, b) => a < b ? a : b);
    final delta = maxC - minC;

    // Hue calculation
    double hue = 0;
    if (delta != 0) {
      if (maxC == r) {
        hue = 60 * (((g - b) / delta) % 6);
      } else if (maxC == g) {
        hue = 60 * (((b - r) / delta) + 2);
      } else {
        hue = 60 * (((r - g) / delta) + 4);
      }
    }
    if (hue < 0) hue += 360;

    // Saturation
    final saturation = maxC == 0 ? 0.0 : delta / maxC;

    // Value (brightness)
    final value = maxC;

    return {'h': hue, 's': saturation, 'v': value};
  }

  /// Classify iris color based on RGB and hue
  IrisColorType _classifyColor(double r, double g, double b, double hue) {
    // Blue iris (hue: 180-260)
    if (hue >= 180 && hue <= 260 && b > r && b > g) {
      return IrisColorType.blue;
    }

    // Green iris (hue: 80-180)
    if (hue >= 80 && hue <= 180 && g > r * 0.9) {
      return IrisColorType.green;
    }

    // Brown iris (low saturation, warm hue)
    if (hue >= 20 && hue <= 40 && r > 0.3) {
      return IrisColorType.brown;
    }

    // Hazel (mixed green/brown)
    if (hue >= 40 && hue <= 80) {
      return IrisColorType.hazel;
    }

    // Amber (yellow-brown, hue 40-60)
    if (hue >= 30 && hue <= 60 && r > g && g > b) {
      return IrisColorType.amber;
    }

    // Gray (low saturation, neutral)
    if ((r + g + b) / 3 > 0.3 && (math.max(r, math.max(g, b)) - math.min(r, math.min(g, b))) < 0.15) {
      return IrisColorType.gray;
    }

    return IrisColorType.mixed;
  }

  /// Find secondary colors in pixel distribution
  List<IrisColorType> _findSecondaryColors(List<img.Pixel> pixels) {
    if (pixels.length < 100) return [];

    // Count pixels by color type
    final colorCounts = <IrisColorType, int>{};

    // Sample a subset for performance
    final sampleSize = math.min(pixels.length, 1000);
    final step = pixels.length ~/ sampleSize;

    for (int i = 0; i < pixels.length; i += step) {
      final pixel = pixels[i];
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;

      final hsv = _rgbToHsv(r, g, b);
      final colorType = _classifyColor(r, g, b, hsv['h']!);

      colorCounts[colorType] = (colorCounts[colorType] ?? 0) + 1;
    }

    // Find colors with significant presence (>10%)
    final threshold = sampleSize * 0.1;
    final secondaryColors = colorCounts.entries
        .where((e) => e.value > threshold)
        .map((e) => e.key)
        .toList();

    // Remove the dominant color if present
    if (secondaryColors.length > 1) {
      secondaryColors.removeAt(0); // Assume first is dominant
    }

    return secondaryColors.take(2).toList(); // Max 2 secondary colors
  }

  /// Calculate color variation across pixels
  double _calculateColorVariation(List<img.Pixel> pixels) {
    if (pixels.length < 10) return 0.0;

    // Calculate standard deviation of hue values
    final hues = <double>[];

    final sampleSize = math.min(pixels.length, 500);
    final step = pixels.length ~/ sampleSize;

    for (int i = 0; i < pixels.length; i += step) {
      final pixel = pixels[i];
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;

      final hsv = _rgbToHsv(r, g, b);
      hues.add(hsv['h']!);
    }

    // Calculate mean
    final mean = hues.reduce((a, b) => a + b) / hues.length;

    // Calculate standard deviation
    final variance = hues
            .map((h) => (h - mean) * (h - mean))
            .reduce((a, b) => a + b) /
        hues.length;

    final stdDev = math.sqrt(variance);

    // Normalize to 0-1 range (360 degrees max std dev)
    return (stdDev / 360).clamp(0.0, 1.0);
  }

  /// Get color histogram for a set of pixels
  Map<String, List<int>> getColorHistogram(List<img.Pixel> pixels) {
    final redHist = List<int>.filled(256, 0);
    final greenHist = List<int>.filled(256, 0);
    final blueHist = List<int>.filled(256, 0);

    for (final pixel in pixels) {
      redHist[pixel.r.toInt()]++;
      greenHist[pixel.g.toInt()]++;
      blueHist[pixel.b.toInt()]++;
    }

    return {
      'red': redHist,
      'green': greenHist,
      'blue': blueHist,
    };
  }

  /// Detect if zone has unusual pigmentation
  bool detectUnusualPigmentation(ColorProfile profile, IrisColorProfile overall) {
    // Compare zone color to overall iris color
    final hueDiff = (profile.hue - _getHueForColor(overall.primaryColor)).abs();

    // If hue differs significantly (>60 degrees)
    if (hueDiff > 60 && hueDiff < 300) { // Avoid wraparound
      return true;
    }

    // Check saturation difference
    if ((profile.saturation - 0.5).abs() > 0.3) {
      return true;
    }

    return false;
  }

  /// Get typical hue for a color type
  double _getHueForColor(IrisColorType colorType) {
    switch (colorType) {
      case IrisColorType.blue:
        return 220;
      case IrisColorType.green:
        return 130;
      case IrisColorType.brown:
        return 30;
      case IrisColorType.hazel:
        return 60;
      case IrisColorType.gray:
        return 0;
      case IrisColorType.amber:
        return 45;
      case IrisColorType.mixed:
        return 0;
    }
  }
}
