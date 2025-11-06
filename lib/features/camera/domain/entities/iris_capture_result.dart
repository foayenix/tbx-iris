// lib/features/camera/domain/entities/iris_capture_result.dart
// Domain entities for iris capture results

import 'dart:math';
import 'dart:typed_data';

/// Represents the result of an iris capture attempt
class IrisCaptureResult {
  final bool isSuccess;
  final Uint8List? leftIrisImage;
  final Uint8List? rightIrisImage;
  final Uint8List? originalImage;
  final double qualityScore;
  final String? errorMessage;
  final IrisQualityMetrics? qualityMetrics;
  final DateTime timestamp;

  const IrisCaptureResult({
    required this.isSuccess,
    this.leftIrisImage,
    this.rightIrisImage,
    this.originalImage,
    required this.qualityScore,
    this.errorMessage,
    this.qualityMetrics,
    required this.timestamp,
  });

  /// Create a successful capture result
  factory IrisCaptureResult.success({
    required Uint8List leftIrisImage,
    required Uint8List rightIrisImage,
    required Uint8List originalImage,
    required double qualityScore,
    required IrisQualityMetrics qualityMetrics,
  }) {
    return IrisCaptureResult(
      isSuccess: true,
      leftIrisImage: leftIrisImage,
      rightIrisImage: rightIrisImage,
      originalImage: originalImage,
      qualityScore: qualityScore,
      qualityMetrics: qualityMetrics,
      timestamp: DateTime.now(),
    );
  }

  /// Create an error result
  factory IrisCaptureResult.error(String message) {
    return IrisCaptureResult(
      isSuccess: false,
      qualityScore: 0.0,
      errorMessage: message,
      timestamp: DateTime.now(),
    );
  }

  /// Create a low quality result
  factory IrisCaptureResult.lowQuality(double score, String reason) {
    return IrisCaptureResult(
      isSuccess: false,
      qualityScore: score,
      errorMessage: reason,
      timestamp: DateTime.now(),
    );
  }

  /// Check if both iris images are available
  bool get hasBothIrises => leftIrisImage != null && rightIrisImage != null;

  /// Get quality rating as a string
  String get qualityRating {
    if (qualityScore >= 0.9) return 'Excellent';
    if (qualityScore >= 0.8) return 'Very Good';
    if (qualityScore >= 0.7) return 'Good';
    if (qualityScore >= 0.6) return 'Fair';
    return 'Poor';
  }

  /// Get quality color for UI display
  String get qualityColor {
    if (qualityScore >= 0.8) return 'green';
    if (qualityScore >= 0.6) return 'orange';
    return 'red';
  }
}

/// Detailed quality metrics for iris capture
class IrisQualityMetrics {
  final double sharpness; // 0.0 to 1.0
  final double brightness; // 0.0 to 1.0
  final double contrast; // 0.0 to 1.0
  final double irisSize; // 0.0 to 1.0 (relative to frame)
  final double centerAlignment; // 0.0 to 1.0
  final bool hasGlare; // Detected glare or reflections
  final bool hasMotionBlur; // Detected motion blur
  final bool isWellLit; // Adequate lighting detected

  const IrisQualityMetrics({
    required this.sharpness,
    required this.brightness,
    required this.contrast,
    required this.irisSize,
    required this.centerAlignment,
    required this.hasGlare,
    required this.hasMotionBlur,
    required this.isWellLit,
  });

  /// Calculate overall quality score
  double get overallScore {
    double score = 0.0;

    // Sharpness is most important (40%)
    score += sharpness * 0.4;

    // Brightness and contrast (25%)
    score += brightness * 0.15;
    score += contrast * 0.1;

    // Size and alignment (20%)
    score += irisSize * 0.1;
    score += centerAlignment * 0.1;

    // Penalties for issues (15%)
    if (!hasGlare) score += 0.05;
    if (!hasMotionBlur) score += 0.05;
    if (isWellLit) score += 0.05;

    return score.clamp(0.0, 1.0);
  }

  /// Get list of quality issues
  List<String> get issues {
    final issues = <String>[];

    if (sharpness < 0.6) {
      issues.add('Image is blurry - hold phone steady');
    }
    if (brightness < 0.4) {
      issues.add('Too dark - move to better lighting');
    }
    if (brightness > 0.9) {
      issues.add('Too bright - reduce direct light');
    }
    if (contrast < 0.5) {
      issues.add('Low contrast - adjust lighting');
    }
    if (irisSize < 0.3) {
      issues.add('Move closer to camera');
    }
    if (irisSize > 0.8) {
      issues.add('Move back from camera');
    }
    if (centerAlignment < 0.7) {
      issues.add('Center your eye in the guide');
    }
    if (hasGlare) {
      issues.add('Glare detected - adjust angle');
    }
    if (hasMotionBlur) {
      issues.add('Motion detected - hold still');
    }
    if (!isWellLit) {
      issues.add('Insufficient lighting');
    }

    return issues;
  }

  /// Check if quality is acceptable for capture
  bool get isAcceptable => overallScore >= 0.6;

  /// Get quality feedback message
  String get feedbackMessage {
    if (overallScore >= 0.8) {
      return 'Excellent! Ready to capture.';
    } else if (overallScore >= 0.6) {
      return 'Good quality. You may proceed.';
    } else if (issues.isNotEmpty) {
      return issues.first; // Show most important issue
    } else {
      return 'Quality too low. Please adjust.';
    }
  }
}

/// Represents detected face and iris landmarks
class IrisLandmarks {
  final List<IrisPoint> leftIrisPoints;
  final List<IrisPoint> rightIrisPoints;
  final IrisPoint leftCenter;
  final IrisPoint rightCenter;
  final double leftIrisRadius;
  final double rightIrisRadius;

  const IrisLandmarks({
    required this.leftIrisPoints,
    required this.rightIrisPoints,
    required this.leftCenter,
    required this.rightCenter,
    required this.leftIrisRadius,
    required this.rightIrisRadius,
  });

  /// Check if both irises are detected
  bool get hasBothIrises =>
      leftIrisPoints.isNotEmpty && rightIrisPoints.isNotEmpty;
}

/// Represents a 2D point with coordinates
class IrisPoint {
  final double x;
  final double y;

  const IrisPoint(this.x, this.y);

  /// Calculate distance to another point
  double distanceTo(IrisPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy); // Using squared distance for efficiency
  }

  /// Calculate angle to another point (in radians)
  double angleTo(IrisPoint other) {
    return atan2(other.y - y, other.x - x);
  }

  @override
  String toString() => 'IrisPoint($x, $y)';
}

/// Camera capture guidance states
enum CaptureGuidanceState {
  initializing('Initializing camera...'),
  ready('Position your eye in the circle'),
  tooClose('Move back from camera'),
  tooFar('Move closer to camera'),
  offCenter('Center your eye in the guide'),
  lowLight('Move to better lighting'),
  glareDetected('Reduce glare - adjust angle'),
  motionBlur('Hold still'),
  processing('Analyzing iris...'),
  success('Capture successful!'),
  error('Capture failed');

  final String message;
  const CaptureGuidanceState(this.message);
}
