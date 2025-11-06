// lib/features/camera/presentation/screens/iris_camera_screen_v2.dart
// Fully integrated iris capture screen with camera, detection, and quality checks

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/services/camera_service.dart';
import '../../data/services/iris_detection_service.dart';
import '../../data/services/iris_extraction_service.dart';
import '../../domain/entities/iris_capture_result.dart';
import '../widgets/iris_guide_overlay.dart';
import 'iris_result_screen.dart';

/// Iris camera capture screen with real camera integration
class IrisCameraScreenV2 extends StatefulWidget {
  const IrisCameraScreenV2({super.key});

  @override
  State<IrisCameraScreenV2> createState() => _IrisCameraScreenV2State();
}

class _IrisCameraScreenV2State extends State<IrisCameraScreenV2>
    with WidgetsBindingObserver {
  // Services
  final CameraService _cameraService = CameraService();
  late final IrisDetectionService _detectionService;
  late final IrisExtractionService _extractionService;

  // State
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isProcessing = false;
  String _guidanceText = 'Initializing...';
  CaptureGuidanceState _guidanceState = CaptureGuidanceState.initializing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectionService = IrisDetectionService();
    _extractionService = IrisExtractionService(_detectionService);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (!_isInitialized || _cameraService.controller == null) return;

    if (state == AppLifecycleState.inactive) {
      _cameraService.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.resumePreview();
    }
  }

  Future<void> _initialize() async {
    // Request camera permission
    final permissionStatus = await Permission.camera.request();

    if (!permissionStatus.isGranted) {
      setState(() {
        _hasPermission = false;
        _guidanceText = 'Camera permission required';
        _isInitialized = true;
      });

      if (permissionStatus.isPermanentlyDenied) {
        _showPermissionDialog();
      }
      return;
    }

    setState(() => _hasPermission = true);

    // Initialize services
    final cameraInitialized = await _cameraService.initialize();
    final detectionInitialized = await _detectionService.initialize();

    if (!cameraInitialized) {
      setState(() {
        _guidanceText = 'Failed to initialize camera';
        _isInitialized = true;
      });
      return;
    }

    setState(() {
      _isInitialized = true;
      _guidanceText = 'Position your eye in the circle';
      _guidanceState = CaptureGuidanceState.ready;
    });

    // Set optimal camera settings for iris capture
    await _cameraService.setFlashMode(FlashMode.off);
    await _cameraService.enableAutoFocus();
  }

  Future<void> _captureImage() async {
    if (!_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _guidanceText = 'Capturing and analyzing...';
      _guidanceState = CaptureGuidanceState.processing;
    });

    try {
      // Capture image
      final imageBytes = await _cameraService.captureImage();

      if (imageBytes == null) {
        _showError('Failed to capture image');
        return;
      }

      // Process image and extract iris regions
      final result = await _extractionService.processImage(imageBytes);

      if (!mounted) return;

      if (result.isSuccess) {
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IrisResultScreen(result: result),
          ),
        );
      } else {
        // Show error or quality feedback
        _showError(result.errorMessage ?? 'Failed to capture iris');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _guidanceText = 'Position your eye in the circle';
          _guidanceState = CaptureGuidanceState.ready;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Iris needs camera access to capture photos of your eye. '
          'Please grant camera permission in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_guidanceText),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                _guidanceText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _initialize,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),

          // Iris guide overlay
          IrisGuideOverlay(guidanceState: _guidanceState),

          // Top guidance text
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                _guidanceText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),

          // Tips card
          Positioned(
            bottom: 180,
            left: 24,
            right: 24,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tips for Best Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TipRow(icon: Icons.wb_sunny, text: 'Use natural lighting'),
                    _TipRow(icon: Icons.remove_red_eye, text: 'Open your eye wide'),
                    _TipRow(icon: Icons.center_focus_strong, text: 'Hold phone steady'),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Capture button
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isProcessing ? 'Analyzing...' : 'Tap to capture',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
