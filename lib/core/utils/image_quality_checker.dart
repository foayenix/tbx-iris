// lib/core/utils/image_quality_checker.dart
// Utility for checking image quality metrics

import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../../features/camera/domain/entities/iris_capture_result.dart';

/// Utility class for checking image quality
class ImageQualityChecker {
  /// Calculate sharpness using Laplacian variance method
  /// Higher value = sharper image
  static Future<double> calculateSharpness(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return 0.0;

      // Convert to grayscale for better edge detection
      final grayscale = img.grayscale(image);

      // Apply Laplacian filter to detect edges
      // Laplacian kernel:
      // 0  1  0
      // 1 -4  1
      // 0  1  0

      double sum = 0.0;
      double sumOfSquares = 0.0;
      int count = 0;

      for (int y = 1; y < grayscale.height - 1; y++) {
        for (int x = 1; x < grayscale.width - 1; x++) {
          // Get surrounding pixels
          final center = grayscale.getPixel(x, y).r.toDouble();
          final top = grayscale.getPixel(x, y - 1).r.toDouble();
          final bottom = grayscale.getPixel(x, y + 1).r.toDouble();
          final left = grayscale.getPixel(x - 1, y).r.toDouble();
          final right = grayscale.getPixel(x + 1, y).r.toDouble();

          // Calculate Laplacian
          final laplacian = (-4 * center) + top + bottom + left + right;

          sum += laplacian;
          sumOfSquares += laplacian * laplacian;
          count++;
        }
      }

      if (count == 0) return 0.0;

      // Calculate variance
      final mean = sum / count;
      final variance = (sumOfSquares / count) - (mean * mean);

      // Normalize to 0-1 range (using empirical threshold of 500 for good quality)
      final sharpness = (variance / 500).clamp(0.0, 1.0);

      return sharpness;
    } catch (e) {
      print('Error calculating sharpness: $e');
      return 0.0;
    }
  }

  /// Calculate brightness (average luminosity)
  static Future<double> calculateBrightness(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return 0.0;

      double totalBrightness = 0.0;
      int count = 0;

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          // Calculate luminosity using standard formula
          final luminosity = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
          totalBrightness += luminosity;
          count++;
        }
      }

      return count > 0 ? totalBrightness / count : 0.0;
    } catch (e) {
      print('Error calculating brightness: $e');
      return 0.0;
    }
  }

  /// Calculate contrast (standard deviation of brightness)
  static Future<double> calculateContrast(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return 0.0;

      // First calculate mean brightness
      double sum = 0.0;
      int count = 0;

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final luminosity = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
          sum += luminosity;
          count++;
        }
      }

      final mean = count > 0 ? sum / count : 0.0;

      // Calculate standard deviation
      double sumSquaredDiff = 0.0;

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final luminosity = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
          final diff = luminosity - mean;
          sumSquaredDiff += diff * diff;
        }
      }

      final variance = count > 0 ? sumSquaredDiff / count : 0.0;
      final stdDev = sqrt(variance);

      // Normalize to 0-1 range (using 70 as empirical good contrast threshold)
      final contrast = (stdDev / 70).clamp(0.0, 1.0);

      return contrast;
    } catch (e) {
      print('Error calculating contrast: $e');
      return 0.0;
    }
  }

  /// Detect if image has glare or overexposed regions
  static Future<bool> detectGlare(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return false;

      int overexposedPixels = 0;
      int totalPixels = 0;

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          // Check if pixel is very bright (potential glare)
          if (pixel.r > 240 && pixel.g > 240 && pixel.b > 240) {
            overexposedPixels++;
          }
          totalPixels++;
        }
      }

      // If more than 10% of pixels are overexposed, consider it glare
      final glarePercentage = totalPixels > 0 ? overexposedPixels / totalPixels : 0.0;
      return glarePercentage > 0.1;
    } catch (e) {
      print('Error detecting glare: $e');
      return false;
    }
  }

  /// Detect motion blur by analyzing edge sharpness
  static Future<bool> detectMotionBlur(Uint8List imageBytes) async {
    try {
      final sharpness = await calculateSharpness(imageBytes);
      // If sharpness is very low, likely motion blur
      return sharpness < 0.3;
    } catch (e) {
      print('Error detecting motion blur: $e');
      return false;
    }
  }

  /// Calculate iris size relative to frame
  /// Takes iris center point and radius
  static double calculateIrisSize({
    required double irisRadius,
    required double frameWidth,
    required double frameHeight,
  }) {
    // Calculate iris diameter in pixels
    final irisDiameter = irisRadius * 2;

    // Calculate frame diagonal for normalization
    final frameDiagonal = sqrt(frameWidth * frameWidth + frameHeight * frameHeight);

    // Normalize iris size (0.0 to 1.0)
    // Optimal iris size is typically 20-50% of frame diagonal
    final relativeSize = (irisDiameter / frameDiagonal) * 2.5;

    return relativeSize.clamp(0.0, 1.0);
  }

  /// Calculate center alignment score
  /// How well centered is the iris in the frame
  static double calculateCenterAlignment({
    required double irisX,
    required double irisY,
    required double frameWidth,
    required double frameHeight,
  }) {
    final frameCenterX = frameWidth / 2;
    final frameCenterY = frameHeight / 2;

    // Calculate distance from center
    final dx = irisX - frameCenterX;
    final dy = irisY - frameCenterY;
    final distance = sqrt(dx * dx + dy * dy);

    // Normalize by frame diagonal
    final frameDiagonal = sqrt(frameWidth * frameWidth + frameHeight * frameHeight);
    final relativeDistance = distance / frameDiagonal;

    // Convert to alignment score (1.0 = perfect center, 0.0 = far from center)
    final alignment = (1.0 - relativeDistance * 4).clamp(0.0, 1.0);

    return alignment;
  }

  /// Comprehensive quality check
  static Future<IrisQualityMetrics> checkQuality({
    required Uint8List imageBytes,
    required double irisX,
    required double irisY,
    required double irisRadius,
    required double frameWidth,
    required double frameHeight,
  }) async {
    // Perform all quality checks
    final sharpness = await calculateSharpness(imageBytes);
    final brightness = await calculateBrightness(imageBytes);
    final contrast = await calculateContrast(imageBytes);
    final hasGlare = await detectGlare(imageBytes);
    final hasMotionBlur = await detectMotionBlur(imageBytes);

    final irisSize = calculateIrisSize(
      irisRadius: irisRadius,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );

    final centerAlignment = calculateCenterAlignment(
      irisX: irisX,
      irisY: irisY,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );

    // Determine if image is well lit
    final isWellLit = brightness >= 0.3 && brightness <= 0.8 && contrast >= 0.4;

    return IrisQualityMetrics(
      sharpness: sharpness,
      brightness: brightness,
      contrast: contrast,
      irisSize: irisSize,
      centerAlignment: centerAlignment,
      hasGlare: hasGlare,
      hasMotionBlur: hasMotionBlur,
      isWellLit: isWellLit,
    );
  }

  /// Quick quality check (faster, less detailed)
  static Future<double> quickQualityCheck(Uint8List imageBytes) async {
    final sharpness = await calculateSharpness(imageBytes);
    final brightness = await calculateBrightness(imageBytes);

    // Simple combined score
    final score = (sharpness * 0.7 + brightness * 0.3);
    return score.clamp(0.0, 1.0);
  }
}

/// Helper function for square root
double sqrt(double value) {
  return value < 0 ? 0 : _sqrt(value);
}

double _sqrt(double x) {
  if (x == 0) return 0;
  double z = x;
  double guess = x / 2;
  while ((z - guess).abs() > 0.001) {
    z = guess;
    guess = (x / z + z) / 2;
  }
  return guess;
}
