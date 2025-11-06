// lib/features/camera/data/services/camera_service.dart
// Camera controller service for managing camera operations

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Service for managing camera operations
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  /// Initialize camera with front camera for selfie mode
  Future<bool> initialize() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Find front camera (for selfie iris capture)
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;

      debugPrint('Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Capture image from camera
  Future<Uint8List?> captureImage() async {
    if (_controller == null || !_isInitialized) {
      debugPrint('Camera not initialized');
      return null;
    }

    try {
      // Capture image
      final XFile image = await _controller!.takePicture();

      // Read as bytes
      final bytes = await image.readAsBytes();

      return bytes;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Start image stream for real-time processing
  Future<void> startImageStream(
    Function(CameraImage image) onImage,
  ) async {
    if (_controller == null || !_isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      await _controller!.startImageStream(onImage);
    } catch (e) {
      debugPrint('Error starting image stream: $e');
    }
  }

  /// Stop image stream
  Future<void> stopImageStream() async {
    if (_controller == null) return;

    try {
      await _controller!.stopImageStream();
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  /// Set zoom level (0.0 to 1.0)
  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null || !_isInitialized) return;

    try {
      final minZoom = await _controller!.getMinZoomLevel();
      final maxZoom = await _controller!.getMaxZoomLevel();
      final targetZoom = minZoom + (maxZoom - minZoom) * zoom;
      await _controller!.setZoomLevel(targetZoom);
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
    }
  }

  /// Lock auto focus on specific point
  Future<void> setFocusPoint(Offset point) async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setFocusMode(FocusMode.locked);
    } catch (e) {
      debugPrint('Error setting focus point: $e');
    }
  }

  /// Enable auto focus
  Future<void> enableAutoFocus() async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Error enabling auto focus: $e');
    }
  }

  /// Set exposure compensation (-1.0 to 1.0)
  Future<void> setExposure(double exposure) async {
    if (_controller == null || !_isInitialized) return;

    try {
      final minExposure = await _controller!.getMinExposureOffset();
      final maxExposure = await _controller!.getMaxExposureOffset();
      final targetExposure = minExposure + (maxExposure - minExposure) *
                            ((exposure + 1.0) / 2.0);
      await _controller!.setExposureOffset(targetExposure);
    } catch (e) {
      debugPrint('Error setting exposure: $e');
    }
  }

  /// Get camera aspect ratio
  double? get aspectRatio => _controller?.value.aspectRatio;

  /// Check if camera is currently capturing
  bool get isCapturing => _controller?.value.isTakingPicture ?? false;

  /// Dispose camera controller
  Future<void> dispose() async {
    try {
      await stopImageStream();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      debugPrint('Camera disposed');
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
  }

  /// Pause camera preview
  Future<void> pausePreview() async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.pausePreview();
    } catch (e) {
      debugPrint('Error pausing preview: $e');
    }
  }

  /// Resume camera preview
  Future<void> resumePreview() async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.resumePreview();
    } catch (e) {
      debugPrint('Error resuming preview: $e');
    }
  }
}
