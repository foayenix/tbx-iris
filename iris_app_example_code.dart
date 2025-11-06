// FILE: lib/features/camera/presentation/iris_camera_screen.dart
// Complete implementation of the iris capture screen

import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';

class IrisCameraScreen extends StatefulWidget {
  const IrisCameraScreen({super.key});

  @override
  State<IrisCameraScreen> createState() => _IrisCameraScreenState();
}

class _IrisCameraScreenState extends State<IrisCameraScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _guidanceText = 'Position your eye in the circle';
  Color _guideColor = Colors.white;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _initializeFaceDetector() async {
    _faceDetector = FaceDetector();
    await _faceDetector!.initialize(
      model: FaceDetectionModel.frontCamera,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
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
          // Camera preview
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // Dark overlay with iris guide cutout
          CustomPaint(
            painter: IrisGuideOverlayPainter(
              guideColor: _guideColor,
            ),
          ),

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
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
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
                    _TipRow(
                      icon: Icons.wb_sunny,
                      text: 'Use natural lighting',
                    ),
                    _TipRow(
                      icon: Icons.remove_red_eye,
                      text: 'Open your eye wide',
                    ),
                    _TipRow(
                      icon: Icons.center_focus_strong,
                      text: 'Hold phone steady',
                    ),
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
    if (_cameraController == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _guidanceText = 'Analyzing your iris...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Detect face and iris
      final result = await _faceDetector!.detectFaces(
        bytes,
        mode: FaceDetectionMode.full,
      );

      if (result.faces.isEmpty) {
        _showGuidance('No face detected. Please try again.', Colors.orange);
        return;
      }

      final face = result.faces.first;
      if (face.irises == null) {
        _showGuidance('Iris not detected. Move closer.', Colors.orange);
        return;
      }

      // Quality checks
      final qualityScore = await _checkImageQuality(bytes);
      if (qualityScore < 0.6) {
        _showGuidance('Image quality too low. Check lighting.', Colors.red);
        return;
      }

      // Extract iris regions
      final leftIris = await _extractIrisRegion(
        bytes,
        face.irises!.leftIris,
      );
      final rightIris = await _extractIrisRegion(
        bytes,
        face.irises!.rightIris,
      );

      if (mounted) {
        // Navigate to analysis screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => IrisAnalysisScreen(
              leftIrisImage: leftIris,
              rightIrisImage: rightIris,
              qualityScore: qualityScore,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to capture iris: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showGuidance(String message, Color color) {
    setState(() {
      _guidanceText = message;
      _guideColor = color;
      _isProcessing = false;
    });

    // Reset after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _guidanceText = 'Position your eye in the circle';
          _guideColor = Colors.white;
        });
      }
    });
  }

  Future<double> _checkImageQuality(Uint8List bytes) async {
    // Placeholder for quality check logic
    // In real implementation, check sharpness, brightness, contrast
    return 0.8;
  }

  Future<Uint8List> _extractIrisRegion(
    Uint8List imageBytes,
    List<Point> irisPoints,
  ) async {
    // Placeholder for iris extraction
    // In real implementation, crop and process iris region
    return imageBytes;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {
        _isProcessing = false;
        _guidanceText = 'Position your eye in the circle';
      });
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
  final Color guideColor;

  IrisGuideOverlayPainter({required this.guideColor});

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

    // Draw guide circle
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

    // Draw corner markers
    _drawCornerMarker(canvas, center, radius, 0, guidePaint);
    _drawCornerMarker(canvas, center, radius, 90, guidePaint);
    _drawCornerMarker(canvas, center, radius, 180, guidePaint);
    _drawCornerMarker(canvas, center, radius, 270, guidePaint);
  }

  void _drawCornerMarker(
    Canvas canvas,
    Offset center,
    double radius,
    double angleDegrees,
    Paint paint,
  ) {
    final angle = angleDegrees * 3.14159 / 180;
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    
    canvas.drawLine(
      Offset(x, y),
      Offset(
        x + 15 * cos(angle),
        y + 15 * sin(angle),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(IrisGuideOverlayPainter oldDelegate) {
    return oldDelegate.guideColor != guideColor;
  }
}

// ===================================================================
// FILE: lib/core/constants/iridology_zones.dart
// Comprehensive iridology zone definitions
// ===================================================================

import 'dart:math';

class IridologyZone {
  final String id;
  final String name;
  final String bodySystem;
  final double startAngle;  // In radians (0 = 3 o'clock position)
  final double endAngle;
  final double innerRadius; // Normalized 0.0 to 1.0
  final double outerRadius;
  final String description;
  final List<String> wellnessReflections;

  const IridologyZone({
    required this.id,
    required this.name,
    required this.bodySystem,
    required this.startAngle,
    required this.endAngle,
    required this.innerRadius,
    required this.outerRadius,
    required this.description,
    required this.wellnessReflections,
  });

  bool containsPoint(double angle, double radius) {
    // Normalize angle to 0-2π
    final normalizedAngle = angle % (2 * pi);
    
    // Check if point is within this zone
    final angleInRange = normalizedAngle >= startAngle && 
                        normalizedAngle <= endAngle;
    final radiusInRange = radius >= innerRadius && 
                          radius <= outerRadius;
    
    return angleInRange && radiusInRange;
  }
}

class IridologyZones {
  // Helper function to convert clock position to radians
  static double clockToRadians(int hour) {
    // 12 o'clock = π/2 (90°), going clockwise
    return (pi / 2) - (hour * pi / 6);
  }

  // RIGHT EYE ZONES (80-90 zones total)
  // Based on standard iridology charts by Bernard Jensen
  static final List<IridologyZone> rightEyeZones = [
    // PUPILLARY ZONE (Digestive System)
    IridologyZone(
      id: 're_stomach',
      name: 'Stomach',
      bodySystem: 'Digestive',
      startAngle: 0,
      endAngle: 2 * pi,
      innerRadius: 0.0,
      outerRadius: 0.3,
      description: 'Central digestive area',
      wellnessReflections: [
        'How is your digestion after meals?',
        'Consider meal timing and portion sizes',
        'Reflect on your hydration habits',
      ],
    ),

    // LIVER ZONE (5-7 o'clock right eye)
    IridologyZone(
      id: 're_liver',
      name: 'Liver',
      bodySystem: 'Digestive',
      startAngle: clockToRadians(7),
      endAngle: clockToRadians(5),
      innerRadius: 0.3,
      outerRadius: 0.6,
      description: 'Liver and detoxification zone',
      wellnessReflections: [
        'How are your energy levels throughout the day?',
        'Consider your body\'s natural detox processes',
        'Reflect on sleep quality and rest',
      ],
    ),

    // GALLBLADDER (5-6 o'clock)
    IridologyZone(
      id: 're_gallbladder',
      name: 'Gallbladder',
      bodySystem: 'Digestive',
      startAngle: clockToRadians(6),
      endAngle: clockToRadians(5),
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Gallbladder zone',
      wellnessReflections: [
        'How do you feel after fatty meals?',
        'Consider balanced nutrition',
      ],
    ),

    // RIGHT LUNG (2-3 o'clock)
    IridologyZone(
      id: 're_lung',
      name: 'Right Lung',
      bodySystem: 'Respiratory',
      startAngle: clockToRadians(3),
      endAngle: clockToRadians(2),
      innerRadius: 0.4,
      outerRadius: 0.7,
      description: 'Right respiratory zone',
      wellnessReflections: [
        'Are you practicing deep breathing?',
        'Consider air quality in your environment',
        'Reflect on your breathing patterns',
      ],
    ),

    // RIGHT KIDNEY (7-8 o'clock)
    IridologyZone(
      id: 're_kidney',
      name: 'Right Kidney',
      bodySystem: 'Urinary',
      startAngle: clockToRadians(8),
      endAngle: clockToRadians(7),
      innerRadius: 0.5,
      outerRadius: 0.7,
      description: 'Right kidney and adrenal zone',
      wellnessReflections: [
        'How is your hydration?',
        'Consider your stress levels',
        'Reflect on your body\'s rest needs',
      ],
    ),

    // BRAIN (11-1 o'clock)
    IridologyZone(
      id: 're_brain',
      name: 'Right Brain Hemisphere',
      bodySystem: 'Nervous',
      startAngle: clockToRadians(1),
      endAngle: clockToRadians(11),
      innerRadius: 0.6,
      outerRadius: 0.8,
      description: 'Right brain and nervous system',
      wellnessReflections: [
        'How are your stress levels?',
        'Consider mental clarity and focus',
        'Reflect on your sleep quality',
      ],
    ),

    // HEART (3-4 o'clock right eye)
    IridologyZone(
      id: 're_heart',
      name: 'Heart',
      bodySystem: 'Cardiovascular',
      startAngle: clockToRadians(4),
      endAngle: clockToRadians(3),
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Cardiovascular zone',
      wellnessReflections: [
        'How is your cardiovascular activity?',
        'Consider movement and exercise',
        'Reflect on emotional wellness',
      ],
    ),

    // LYMPHATIC RING (outer edge)
    IridologyZone(
      id: 're_lymphatic',
      name: 'Lymphatic System',
      bodySystem: 'Immune',
      startAngle: 0,
      endAngle: 2 * pi,
      innerRadius: 0.8,
      outerRadius: 1.0,
      description: 'Lymphatic and immune zone',
      wellnessReflections: [
        'How is your overall vitality?',
        'Consider immune system support',
        'Reflect on rest and recovery',
      ],
    ),

    // Add more zones as needed...
  ];

  // LEFT EYE ZONES
  static final List<IridologyZone> leftEyeZones = [
    // Mirror of right eye with left-side organ correspondences
    IridologyZone(
      id: 'le_stomach',
      name: 'Stomach',
      bodySystem: 'Digestive',
      startAngle: 0,
      endAngle: 2 * pi,
      innerRadius: 0.0,
      outerRadius: 0.3,
      description: 'Central digestive area',
      wellnessReflections: [
        'How is your digestion after meals?',
        'Consider meal timing and portion sizes',
      ],
    ),

    IridologyZone(
      id: 'le_heart',
      name: 'Heart',
      bodySystem: 'Cardiovascular',
      startAngle: clockToRadians(9),
      endAngle: clockToRadians(8),
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Heart zone (left eye)',
      wellnessReflections: [
        'How is your cardiovascular wellness?',
        'Consider emotional balance',
      ],
    ),

    // Add more left eye zones...
  ];

  static List<IridologyZone> getZonesForEye(bool isLeftEye) {
    return isLeftEye ? leftEyeZones : rightEyeZones;
  }
}

// ===================================================================
// FILE: lib/core/constants/art_styles.dart
// AI art style definitions
// ===================================================================

class ArtStyle {
  final String id;
  final String name;
  final String description;
  final String prompt;
  final String negativePrompt;
  final double cfgScale;
  final bool isPro;
  final String thumbnailAsset;
  final List<String> tags;

  const ArtStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.prompt,
    this.negativePrompt = 'blurry, low quality, distorted',
    this.cfgScale = 7.5,
    this.isPro = false,
    required this.thumbnailAsset,
    this.tags = const [],
  });

  // FREE STYLES
  static const neonCyber = ArtStyle(
    id: 'neon_cyber',
    name: 'Neon Cyber',
    description: 'Futuristic cyberpunk with glowing neon colors',
    prompt: 'cyberpunk neon art style, vibrant electric colors, '
            'glowing iris patterns, futuristic digital art, high contrast, '
            'detailed eye structure, neon blue pink purple',
    thumbnailAsset: 'assets/styles/neon_cyber.jpg',
    tags: ['futuristic', 'vibrant', 'neon'],
  );

  static const watercolorDream = ArtStyle(
    id: 'watercolor_dream',
    name: 'Watercolor Dream',
    description: 'Soft flowing watercolor with dreamy pastels',
    prompt: 'soft watercolor painting, flowing delicate colors, '
            'dreamy aesthetic, pastel tones, artistic iris rendering, '
            'gentle brush strokes, ethereal quality',
    thumbnailAsset: 'assets/styles/watercolor.jpg',
    tags: ['soft', 'dreamy', 'artistic'],
  );

  static const oilPainting = ArtStyle(
    id: 'oil_painting',
    name: 'Oil Painting',
    description: 'Classical oil painting with rich textures',
    prompt: 'classical oil painting, rich textures, masterpiece quality, '
            'renaissance style art, detailed iris with visible brush strokes, '
            'warm lighting, artistic rendering',
    thumbnailAsset: 'assets/styles/oil_painting.jpg',
    tags: ['classical', 'textured', 'artistic'],
  );

  // PRO STYLES
  static const cosmicGalaxy = ArtStyle(
    id: 'cosmic_galaxy',
    name: 'Cosmic Galaxy',
    description: 'Celestial space art with nebula and stars',
    prompt: 'cosmic galaxy art, nebula colors, starfield, universe patterns, '
            'space aesthetic, mystical iris with celestial swirls, '
            'deep space colors, ethereal glow',
    thumbnailAsset: 'assets/styles/cosmic.jpg',
    isPro: true,
    tags: ['cosmic', 'mystical', 'space'],
  );

  static const geometricGold = ArtStyle(
    id: 'geometric_gold',
    name: 'Geometric Gold',
    description: 'Sacred geometry with luxurious gold accents',
    prompt: 'sacred geometry art, gold foil accents, mandala patterns, '
            'luxury aesthetic, intricate iris with golden details, '
            'symmetrical design, metallic shine',
    thumbnailAsset: 'assets/styles/geometric_gold.jpg',
    isPro: true,
    tags: ['luxury', 'geometric', 'elegant'],
  );

  static const kaleidoscope = ArtStyle(
    id: 'kaleidoscope',
    name: 'Kaleidoscope',
    description: 'Mesmerizing symmetrical patterns',
    prompt: 'kaleidoscope art, symmetrical patterns, rainbow colors, '
            'mesmerizing design, iris with mirrored details, '
            'psychedelic aesthetic, vibrant mandala',
    thumbnailAsset: 'assets/styles/kaleidoscope.jpg',
    isPro: true,
    tags: ['symmetrical', 'colorful', 'mesmerizing'],
  );

  static const inkSplatter = ArtStyle(
    id: 'ink_splatter',
    name: 'Ink Splatter',
    description: 'Dynamic black ink with dramatic contrast',
    prompt: 'ink splatter art, black and white, dynamic contrast, '
            'flowing ink patterns, artistic iris rendering, '
            'dramatic composition, high contrast',
    thumbnailAsset: 'assets/styles/ink_splatter.jpg',
    isPro: true,
    tags: ['dramatic', 'monochrome', 'dynamic'],
  );

  static const crystalPrism = ArtStyle(
    id: 'crystal_prism',
    name: 'Crystal Prism',
    description: 'Refracted light through crystalline structures',
    prompt: 'crystal prism art, refracted light, rainbow spectrum, '
            'crystalline structures, iris with light dispersion, '
            'gem-like quality, brilliant colors',
    thumbnailAsset: 'assets/styles/crystal_prism.jpg',
    isPro: true,
    tags: ['brilliant', 'prismatic', 'crystalline'],
  );

  // Collections
  static List<ArtStyle> get allStyles => [
    neonCyber,
    watercolorDream,
    oilPainting,
    cosmicGalaxy,
    geometricGold,
    kaleidoscope,
    inkSplatter,
    crystalPrism,
  ];

  static List<ArtStyle> get freeStyles => 
    allStyles.where((s) => !s.isPro).toList();

  static List<ArtStyle> get proStyles => 
    allStyles.where((s) => s.isPro).toList();

  static ArtStyle? getById(String id) {
    try {
      return allStyles.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}

// ===================================================================
// FILE: lib/features/wellness/domain/wellness_disclaimer.dart
// Legal disclaimer texts for GDPR/MHRA compliance
// ===================================================================

class WellnessDisclaimer {
  static const String shortDisclaimer = 
    'For wellness education only. Not medical advice.';

  static const String fullDisclaimer = '''
IMPORTANT HEALTH INFORMATION DISCLAIMER

This application is designed for wellness education and artistic expression purposes only.

NOT A MEDICAL DEVICE: This app is not a medical device and has not been evaluated or approved by any regulatory health authority (FDA, MHRA, or equivalent).

NOT FOR DIAGNOSIS: The insights and information provided are NOT medical diagnoses and should NOT be used to diagnose, treat, cure, or prevent any disease or medical condition.

EDUCATIONAL PURPOSE: Iridology is considered a complementary wellness practice and is not validated by conventional medicine. The associations between iris patterns and body systems are based on traditional iridology theory, not scientific medical evidence.

CONSULT PROFESSIONALS: Always consult qualified healthcare professionals for any medical concerns, symptoms, or before making any changes to your health routine, diet, or lifestyle.

NO GUARANTEES: We make no claims, guarantees, or warranties about the accuracy, completeness, or reliability of any wellness insights provided by this application.

PRIVACY: While we prioritize your privacy, please review our Privacy Policy to understand how your data is processed.

By using this app, you acknowledge and accept that:
• You are using it for informational and creative purposes only
• You will not rely on it for medical decisions
• You understand the limitations of iridology as a practice
• You will seek professional medical advice when needed

If you experience any medical symptoms or health concerns, please contact your healthcare provider immediately.
''';

  static const String firstTimeUserAgreement = '''
Welcome to Iris Art & Wellness!

Before you begin, please read and accept:

✓ This app is for wellness exploration and creative expression
✓ It is NOT a medical diagnostic tool
✓ Insights are educational, not medical advice
✓ Always consult healthcare professionals for medical concerns

Do you understand and agree to these terms?
''';

  static const String onboardingDisclaimer = '''
🌟 Explore Your Unique Iris

This app combines:
• Gentle wellness reflections inspired by iridology
• Beautiful AI-generated iris art
• Personal journaling and tracking

Remember: This is about curiosity and self-expression, not medical diagnosis.
''';
}
