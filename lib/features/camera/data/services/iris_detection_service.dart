// lib/features/camera/data/services/iris_detection_service.dart
// Service for detecting faces and iris landmarks in images

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../../domain/entities/iris_capture_result.dart';

/// Service for iris and face detection
/// NOTE: This is a placeholder implementation that demonstrates the structure.
/// In production, integrate with face_detection_tflite or similar ML package.
class IrisDetectionService {
  bool _isInitialized = false;

  /// Initialize the detection service
  /// In production, this would initialize ML models
  Future<bool> initialize() async {
    try {
      // TODO: Initialize face detection ML model
      // await FaceDetector.initialize(model: FaceDetectionModel.frontCamera);

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing iris detection: $e');
      return false;
    }
  }

  /// Detect faces and iris landmarks in an image
  Future<IrisLandmarks?> detectIrisLandmarks(Uint8List imageBytes) async {
    if (!_isInitialized) {
      print('Detection service not initialized');
      return null;
    }

    try {
      // TODO: Replace with actual ML-based face/iris detection
      // For now, using a mock implementation for structure demonstration
      return await _mockDetectIris(imageBytes);

      /* Production implementation would be:

      final result = await faceDetector.detectFaces(
        imageBytes,
        mode: FaceDetectionMode.full,
      );

      if (result.faces.isEmpty) {
        return null;
      }

      final face = result.faces.first;
      if (face.irises == null) {
        return null;
      }

      return IrisLandmarks(
        leftIrisPoints: _convertPoints(face.irises!.leftIris),
        rightIrisPoints: _convertPoints(face.irises!.rightIris),
        leftCenter: _calculateCenter(face.irises!.leftIris),
        rightCenter: _calculateCenter(face.irises!.rightIris),
        leftIrisRadius: _calculateRadius(face.irises!.leftIris),
        rightIrisRadius: _calculateRadius(face.irises!.rightIris),
      );
      */
    } catch (e) {
      print('Error detecting iris: $e');
      return null;
    }
  }

  /// Mock iris detection for demonstration
  /// This simulates iris detection by finding dark circular regions (pupils)
  Future<IrisLandmarks?> _mockDetectIris(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // For mock purposes, assume eyes are roughly at standard face positions
      // In a real selfie: left eye at ~1/3, right eye at ~2/3 of width
      // Eyes typically at ~40% height from top

      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      // Estimated positions (for front-facing selfie camera)
      final rightEyeX = imageWidth * 0.35; // Note: right/left are flipped in selfie
      final leftEyeX = imageWidth * 0.65;
      final eyeY = imageHeight * 0.40;

      // Estimate iris radius as ~7% of image width
      final irisRadius = imageWidth * 0.07;

      // Generate circular points around estimated iris positions
      final leftIrisPoints = _generateCircularPoints(
        center: IrisPoint(leftEyeX, eyeY),
        radius: irisRadius,
        numPoints: 16,
      );

      final rightIrisPoints = _generateCircularPoints(
        center: IrisPoint(rightEyeX, eyeY),
        radius: irisRadius,
        numPoints: 16,
      );

      return IrisLandmarks(
        leftIrisPoints: leftIrisPoints,
        rightIrisPoints: rightIrisPoints,
        leftCenter: IrisPoint(leftEyeX, eyeY),
        rightCenter: IrisPoint(rightEyeX, eyeY),
        leftIrisRadius: irisRadius,
        rightIrisRadius: irisRadius,
      );
    } catch (e) {
      print('Error in mock detection: $e');
      return null;
    }
  }

  /// Generate points in a circle
  List<IrisPoint> _generateCircularPoints({
    required IrisPoint center,
    required double radius,
    required int numPoints,
  }) {
    final points = <IrisPoint>[];

    for (int i = 0; i < numPoints; i++) {
      final angle = (2 * math.pi * i) / numPoints;
      final x = center.x + radius * math.cos(angle);
      final y = center.y + radius * math.sin(angle);
      points.add(IrisPoint(x, y));
    }

    return points;
  }

  /// Calculate center point from list of points
  IrisPoint _calculateCenter(List<IrisPoint> points) {
    if (points.isEmpty) return const IrisPoint(0, 0);

    double sumX = 0;
    double sumY = 0;

    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
    }

    return IrisPoint(
      sumX / points.length,
      sumY / points.length,
    );
  }

  /// Calculate radius from list of points
  double _calculateRadius(List<IrisPoint> points) {
    if (points.length < 2) return 0.0;

    final center = _calculateCenter(points);
    double totalDistance = 0;

    for (final point in points) {
      final dx = point.x - center.x;
      final dy = point.y - center.y;
      totalDistance += math.sqrt(dx * dx + dy * dy);
    }

    return totalDistance / points.length;
  }

  /// Check if detected iris meets quality requirements
  bool isIrisDetectionValid(IrisLandmarks landmarks) {
    // Check if both irises are detected
    if (!landmarks.hasBothIrises) {
      return false;
    }

    // Check if iris size is reasonable (not too small or too large)
    final minRadius = 10.0; // pixels
    final maxRadius = 200.0; // pixels

    if (landmarks.leftIrisRadius < minRadius ||
        landmarks.leftIrisRadius > maxRadius ||
        landmarks.rightIrisRadius < minRadius ||
        landmarks.rightIrisRadius > maxRadius) {
      return false;
    }

    // Check if both eyes are roughly at same height (not tilted too much)
    final heightDiff = (landmarks.leftCenter.y - landmarks.rightCenter.y).abs();
    final maxHeightDiff = landmarks.leftIrisRadius * 0.5;

    if (heightDiff > maxHeightDiff) {
      return false;
    }

    // Check if eye distance is reasonable
    final eyeDistance = landmarks.leftCenter.distanceTo(landmarks.rightCenter);
    final minEyeDistance = landmarks.leftIrisRadius * 2;
    final maxEyeDistance = landmarks.leftIrisRadius * 10;

    if (eyeDistance < minEyeDistance || eyeDistance > maxEyeDistance) {
      return false;
    }

    return true;
  }

  /// Get guidance message based on detection state
  String getGuidanceMessage(IrisLandmarks? landmarks, img.Image image) {
    if (landmarks == null) {
      return 'No face detected. Position your face in the frame.';
    }

    if (!landmarks.hasBothIrises) {
      return 'Both eyes must be visible.';
    }

    // Check iris size
    final imageWidth = image.width.toDouble();
    final irisSize = (landmarks.leftIrisRadius * 2) / imageWidth;

    if (irisSize < 0.1) {
      return 'Move closer to the camera.';
    }

    if (irisSize > 0.4) {
      return 'Move back from the camera.';
    }

    // Check centering
    final centerX = image.width / 2;
    final centerY = image.height / 2;
    final avgEyeX = (landmarks.leftCenter.x + landmarks.rightCenter.x) / 2;
    final avgEyeY = (landmarks.leftCenter.y + landmarks.rightCenter.y) / 2;

    final offsetX = (avgEyeX - centerX).abs() / imageWidth;
    final offsetY = (avgEyeY - centerY).abs() / image.height;

    if (offsetX > 0.15 || offsetY > 0.15) {
      return 'Center your eyes in the frame.';
    }

    // Check tilt
    final heightDiff = (landmarks.leftCenter.y - landmarks.rightCenter.y).abs();
    if (heightDiff > landmarks.leftIrisRadius * 0.3) {
      return 'Keep your head level.';
    }

    return 'Perfect! Ready to capture.';
  }

  /// Dispose resources
  Future<void> dispose() async {
    // TODO: Dispose ML models
    _isInitialized = false;
  }
}
