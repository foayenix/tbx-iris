// lib/features/camera/data/services/iris_extraction_service.dart
// Service for extracting and processing iris regions from images

import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../domain/entities/iris_capture_result.dart';
import '../../../../core/utils/image_quality_checker.dart';
import 'iris_detection_service.dart';

/// Service for extracting iris regions from captured images
class IrisExtractionService {
  final IrisDetectionService _detectionService;

  IrisExtractionService(this._detectionService);

  /// Process captured image and extract iris regions
  Future<IrisCaptureResult> processImage(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return IrisCaptureResult.error('Failed to decode image');
      }

      // Detect iris landmarks
      final landmarks = await _detectionService.detectIrisLandmarks(imageBytes);
      if (landmarks == null) {
        return IrisCaptureResult.error('No face detected. Please position your face in the frame.');
      }

      if (!landmarks.hasBothIrises) {
        return IrisCaptureResult.error('Both eyes must be visible in the frame.');
      }

      // Validate detection quality
      if (!_detectionService.isIrisDetectionValid(landmarks)) {
        return IrisCaptureResult.error(_detectionService.getGuidanceMessage(landmarks, image));
      }

      // Extract iris regions
      final leftIrisImage = await _extractIrisRegion(
        image,
        landmarks.leftCenter,
        landmarks.leftIrisRadius,
      );

      final rightIrisImage = await _extractIrisRegion(
        image,
        landmarks.rightCenter,
        landmarks.rightIrisRadius,
      );

      if (leftIrisImage == null || rightIrisImage == null) {
        return IrisCaptureResult.error('Failed to extract iris regions');
      }

      // Check image quality
      final qualityMetrics = await ImageQualityChecker.checkQuality(
        imageBytes: imageBytes,
        irisX: landmarks.leftCenter.x,
        irisY: landmarks.leftCenter.y,
        irisRadius: landmarks.leftIrisRadius,
        frameWidth: image.width.toDouble(),
        frameHeight: image.height.toDouble(),
      );

      // Validate quality meets minimum threshold
      if (!qualityMetrics.isAcceptable) {
        return IrisCaptureResult.lowQuality(
          qualityMetrics.overallScore,
          qualityMetrics.feedbackMessage,
        );
      }

      // Encode extracted images as JPEG
      final leftIrisBytes = Uint8List.fromList(img.encodeJpg(leftIrisImage, quality: 95));
      final rightIrisBytes = Uint8List.fromList(img.encodeJpg(rightIrisImage, quality: 95));

      // Return successful result
      return IrisCaptureResult.success(
        leftIrisImage: leftIrisBytes,
        rightIrisImage: rightIrisBytes,
        originalImage: imageBytes,
        qualityScore: qualityMetrics.overallScore,
        qualityMetrics: qualityMetrics,
      );
    } catch (e) {
      print('Error processing image: $e');
      return IrisCaptureResult.error('Failed to process image: $e');
    }
  }

  /// Extract iris region from image
  Future<img.Image?> _extractIrisRegion(
    img.Image sourceImage,
    IrisPoint center,
    double radius,
  ) async {
    try {
      // Calculate crop size with padding
      // We want to capture the iris plus some surrounding area
      final padding = radius * 0.5; // 50% padding
      final cropRadius = radius + padding;
      final cropSize = (cropRadius * 2).toInt();

      // Calculate crop bounds
      final left = (center.x - cropRadius).toInt();
      final top = (center.y - cropRadius).toInt();

      // Ensure bounds are within image
      if (left < 0 ||
          top < 0 ||
          left + cropSize > sourceImage.width ||
          top + cropSize > sourceImage.height) {
        print('Crop bounds outside image');
        return null;
      }

      // Crop the region
      final cropped = img.copyCrop(
        sourceImage,
        x: left,
        y: top,
        width: cropSize,
        height: cropSize,
      );

      // Resize to standard size for consistency
      final standardSize = 512; // Standard iris image size
      final resized = img.copyResize(
        cropped,
        width: standardSize,
        height: standardSize,
        interpolation: img.Interpolation.cubic,
      );

      // Apply enhancement
      final enhanced = _enhanceIrisImage(resized);

      return enhanced;
    } catch (e) {
      print('Error extracting iris region: $e');
      return null;
    }
  }

  /// Enhance iris image (improve contrast, sharpness)
  img.Image _enhanceIrisImage(img.Image image) {
    // Adjust contrast
    img.Image enhanced = img.adjustColor(
      image,
      contrast: 1.2,
      saturation: 1.1,
    );

    // Apply slight sharpening
    enhanced = _applySharpen(enhanced);

    return enhanced;
  }

  /// Apply sharpening filter
  img.Image _applySharpen(img.Image image) {
    // Unsharp mask parameters
    const double amount = 0.5;
    const double threshold = 0;

    // Create a blurred version
    final blurred = img.gaussianBlur(image, radius: 2);

    // Create sharpened version by combining original and blurred
    final sharpened = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final original = image.getPixel(x, y);
        final blur = blurred.getPixel(x, y);

        // Calculate sharpened values
        final r = _sharpenChannel(original.r.toInt(), blur.r.toInt(), amount, threshold);
        final g = _sharpenChannel(original.g.toInt(), blur.g.toInt(), amount, threshold);
        final b = _sharpenChannel(original.b.toInt(), blur.b.toInt(), amount, threshold);

        sharpened.setPixelRgba(x, y, r, g, b, original.a.toInt());
      }
    }

    return sharpened;
  }

  /// Sharpen individual color channel
  int _sharpenChannel(int original, int blur, double amount, double threshold) {
    final diff = original - blur;

    if (diff.abs() > threshold) {
      final sharpened = original + (diff * amount).toInt();
      return sharpened.clamp(0, 255);
    }

    return original;
  }

  /// Create a circular mask for iris region
  img.Image createIrisMask(img.Image irisImage) {
    final mask = img.Image(width: irisImage.width, height: irisImage.height);

    final centerX = mask.width / 2;
    final centerY = mask.height / 2;
    final radius = mask.width / 2;

    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance <= radius) {
          // Inside circle - use original pixel
          final pixel = irisImage.getPixel(x, y);
          mask.setPixel(x, y, pixel);
        } else {
          // Outside circle - black
          mask.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return mask;
  }

  /// Normalize iris image for consistent analysis
  img.Image normalizeIrisImage(img.Image irisImage) {
    // Convert to grayscale for analysis
    final grayscale = img.grayscale(irisImage);

    // Normalize histogram
    final normalized = img.normalize(grayscale, min: 0, max: 255);

    return normalized;
  }

  /// Extract color histogram from iris
  Map<String, List<int>> extractColorHistogram(img.Image irisImage) {
    final redHist = List<int>.filled(256, 0);
    final greenHist = List<int>.filled(256, 0);
    final blueHist = List<int>.filled(256, 0);

    for (int y = 0; y < irisImage.height; y++) {
      for (int x = 0; x < irisImage.width; x++) {
        final pixel = irisImage.getPixel(x, y);
        redHist[pixel.r.toInt()]++;
        greenHist[pixel.g.toInt()]++;
        blueHist[pixel.b.toInt()]++;
      }
    }

    return {
      'red': redHist,
      'green': greenHist,
      'blue': blueHist,
    };
  }
}

/// Helper function for square root
double sqrt(double value) {
  if (value <= 0) return 0;
  double guess = value / 2;
  double lastGuess = 0;

  while ((guess - lastGuess).abs() > 0.001) {
    lastGuess = guess;
    guess = (guess + value / guess) / 2;
  }

  return guess;
}
