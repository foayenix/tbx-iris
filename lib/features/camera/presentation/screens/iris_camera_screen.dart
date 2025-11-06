// lib/features/camera/presentation/screens/iris_camera_screen.dart
// Iris capture screen with camera and guided overlay
// Complete implementation ready for camera and face detection integration

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class IrisCameraScreen extends StatefulWidget {
  const IrisCameraScreen({super.key});

  @override
  State<IrisCameraScreen> createState() => _IrisCameraScreenState();
}

class _IrisCameraScreenState extends State<IrisCameraScreen> {
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isProcessing = false;
  String _guidanceText = 'Requesting camera permission...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();

      if (status.isGranted) {
        setState(() {
          _hasPermission = true;
          _guidanceText = 'Position your eye in the circle';
          _isInitialized = true;
        });
      } else if (status.isDenied) {
        setState(() {
          _guidanceText = 'Camera permission denied';
          _isInitialized = true;
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _guidanceText = 'Camera permission permanently denied';
          _isInitialized = true;
        });
        _showPermissionDialog();
      }
    } catch (e) {
      setState(() {
        _guidanceText = 'Failed to initialize camera: $e';
        _isInitialized = true;
      });
    }
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
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _initializeCamera();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview placeholder
          // TODO: Replace with actual camera preview when camera package is integrated
          Container(
            color: Colors.grey.shade900,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Preview',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camera integration will be added in Phase 2',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Iris guide overlay
          CustomPaint(
            painter: IrisGuideOverlayPainter(),
          ),

          // Top guidance text
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 0,
            right: 0,
            child: Text(
              _guidanceText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                  ),
                ],
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
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
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

  Future<void> _captureImage() async {
    setState(() => _isProcessing = true);

    // TODO: Implement actual image capture in Phase 2
    // This is a placeholder for now
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera capture will be implemented in Phase 2!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class IrisGuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Guide circle
    final guidePaint = Paint()
      ..color = Colors.white
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

    // Draw guide circle
    canvas.drawCircle(center, radius, guidePaint);

    // Draw crosshair
    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
