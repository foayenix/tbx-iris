# Iris App - Technical Architecture & Implementation Guide

## Executive Summary

This document outlines the complete technical architecture for building a Flutter mobile application that combines iris photography, iridology-based wellness insights, and AI-powered art generation. The app is designed with privacy-first principles, GDPR/MHRA compliance, and a freemium monetization model.

---

## 1. Technology Stack

### Core Framework
- **Flutter SDK**: 3.24+ (stable channel)
- **Dart**: 3.5+
- **State Management**: Riverpod 2.x or Bloc 8.x
- **Local Database**: Hive 2.x or Drift 2.x (SQLite)
- **Cloud Storage**: Firebase Storage or AWS S3

### Computer Vision & ML
- **Iris Detection**: `face_detection_tflite` package
  - Uses Google MediaPipe models with TensorFlow Lite
  - Provides on-device iris landmark detection
  - Supports both iOS and Android
  
- **Image Processing**: `image` package (Dart native)
  - Image manipulation and enhancement
  - Color extraction and analysis

- **Quality Check**: Custom implementation using:
  - Sharpness detection (Laplacian variance)
  - Brightness analysis
  - Pupil dilation validation

### AI Art Generation
- **Primary API**: Stability AI REST API
  - Text-to-image generation
  - Image-to-image transformation
  - Style transfer capabilities
  
- **Alternative APIs**:
  - Replicate.com (backup option)
  - RunPod (cost-effective alternative)
  
- **API Integration**: `dio` package for HTTP requests

### UI/UX Components
- **Camera**: `camera` package (official Flutter plugin)
- **Image Picker**: `image_picker` package
- **Animations**: Built-in Flutter animations + `lottie` for complex sequences
- **Charts**: `fl_chart` for wellness tracking visualizations
- **Image Display**: `cached_network_image` for optimized loading

### Backend & Services
- **Authentication**: Firebase Auth or Supabase Auth
- **Cloud Functions**: Firebase Cloud Functions (Node.js/Dart)
- **Analytics**: Firebase Analytics + Mixpanel
- **Crash Reporting**: Sentry or Firebase Crashlytics
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### Payment Processing
- **In-App Purchases**: 
  - `in_app_purchase` package (iOS/Android)
  - RevenueCat (wrapper for easier subscription management)
- **Merchandise**: Printful API or Printify API integration

### Legal & Compliance
- **Privacy**: On-device processing by default
- **Data Encryption**: `flutter_secure_storage` for sensitive data
- **Disclaimers**: Prominent wellness education disclaimers

---

## 2. App Architecture

### Design Pattern
**Clean Architecture with Feature-First Organization**

```
lib/
├── core/
│   ├── constants/
│   │   ├── iridology_zones.dart        # Iris zone mappings
│   │   ├── art_styles.dart             # Available art styles
│   │   └── wellness_insights.dart      # Insight templates
│   ├── theme/
│   ├── utils/
│   └── errors/
├── features/
│   ├── camera/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── iris_analysis/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   │       ├── iris_segmentation_service.dart
│   │   │       └── iridology_mapping_service.dart
│   │   ├── domain/
│   │   └── presentation/
│   ├── art_generation/
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── stability_ai_service.dart
│   │   ├── domain/
│   │   └── presentation/
│   ├── wellness/
│   ├── history/
│   ├── social/
│   └── profile/
└── main.dart
```

---

## 3. Core Features Implementation

### 3.1 Iris Capture Module

**Key Requirements:**
- Guided camera overlay with iris positioning guide
- Real-time quality validation
- Sharpness and lighting checks
- Liveness detection (blink detection)

**Implementation using `face_detection_tflite`:**

```dart
import 'package:face_detection_tflite/face_detection_tflite.dart';

class IrisCapture {
  final FaceDetector _detector = FaceDetector();
  
  Future<void> initialize() async {
    await _detector.initialize(
      model: FaceDetectionModel.frontCamera, // For selfie mode
    );
  }
  
  Future<IrisCaptureResult> captureIris(Uint8List imageBytes) async {
    // Detect face and iris landmarks
    final result = await _detector.detectFaces(
      imageBytes,
      mode: FaceDetectionMode.full, // Full mode provides iris detection
    );
    
    if (result.faces.isEmpty) {
      return IrisCaptureResult.error('No face detected');
    }
    
    final face = result.faces.first;
    final leftIris = face.irises?.leftIris;
    final rightIris = face.irises?.rightIris;
    
    if (leftIris == null || rightIris == null) {
      return IrisCaptureResult.error('Iris not clearly visible');
    }
    
    // Quality checks
    final qualityScore = await _performQualityChecks(
      imageBytes,
      leftIris,
      rightIris,
    );
    
    if (qualityScore < 0.7) {
      return IrisCaptureResult.lowQuality(qualityScore);
    }
    
    // Extract iris regions
    final leftIrisImage = await _extractIrisRegion(imageBytes, leftIris);
    final rightIrisImage = await _extractIrisRegion(imageBytes, rightIris);
    
    return IrisCaptureResult.success(
      leftIris: leftIrisImage,
      rightIris: rightIrisImage,
      qualityScore: qualityScore,
    );
  }
  
  Future<double> _performQualityChecks(
    Uint8List imageBytes,
    List<Point> leftIris,
    List<Point> rightIris,
  ) async {
    // Sharpness check using Laplacian variance
    final sharpness = await _calculateSharpness(imageBytes);
    
    // Brightness check
    final brightness = await _calculateBrightness(imageBytes);
    
    // Iris size check (too small = too far, too large = too close)
    final irisSize = _calculateIrisSize(leftIris);
    
    // Composite quality score
    return (sharpness * 0.5) + (brightness * 0.3) + (irisSize * 0.2);
  }
}
```

**Camera UI with Overlay:**

```dart
class IrisCameraScreen extends StatefulWidget {
  @override
  State<IrisCameraScreen> createState() => _IrisCameraScreenState();
}

class _IrisCameraScreenState extends State<IrisCameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  String _guidance = 'Position your eye in the circle';
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    await _controller!.initialize();
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Stack(
      children: [
        // Camera preview
        CameraPreview(_controller!),
        
        // Overlay with iris guide
        CustomPaint(
          painter: IrisGuidePainter(),
          child: Container(),
        ),
        
        // Guidance text
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Text(
            _guidance,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Capture button
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              onPressed: _isProcessing ? null : _captureImage,
              child: _isProcessing 
                ? const CircularProgressIndicator()
                : const Icon(Icons.camera),
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _captureImage() async {
    setState(() => _isProcessing = true);
    
    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Process with iris detection
      final irisCapture = IrisCapture();
      await irisCapture.initialize();
      final result = await irisCapture.captureIris(bytes);
      
      if (result.isSuccess) {
        // Navigate to analysis screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IrisAnalysisScreen(result: result),
          ),
        );
      } else {
        // Show error guidance
        setState(() => _guidance = result.errorMessage);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

class IrisGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    
    // Draw outer circle guide
    canvas.drawCircle(center, radius, paint);
    
    // Draw crosshair
    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

### 3.2 Iridology Mapping Service

Iridology charts divide the iris into approximately 60-90 zones, with each zone corresponding to specific organs and body systems. The charts follow a clock-like pattern, where specific areas correlate to different parts of the body.

**Iridology Zone Data Structure:**

```dart
class IridologyZone {
  final String id;
  final String name;
  final String bodySystem;
  final double startAngle; // In radians
  final double endAngle;
  final double innerRadius; // Normalized 0-1
  final double outerRadius;
  final String description;
  final List<String> wellnessInsights;
  
  const IridologyZone({
    required this.id,
    required this.name,
    required this.bodySystem,
    required this.startAngle,
    required this.endAngle,
    required this.innerRadius,
    required this.outerRadius,
    required this.description,
    required this.wellnessInsights,
  });
}

// Define zones based on standard iridology charts
class IridologyZones {
  // Example zones for right eye
  static const List<IridologyZone> rightEyeZones = [
    IridologyZone(
      id: 'digestive_zone',
      name: 'Digestive System',
      bodySystem: 'Digestive',
      startAngle: 5 * pi / 6,   // 5 o'clock
      endAngle: 7 * pi / 6,     // 7 o'clock
      innerRadius: 0.3,
      outerRadius: 0.5,
      description: 'Area associated with liver, gallbladder, and digestive organs',
      wellnessInsights: [
        'Consider hydration levels',
        'Reflect on dietary patterns',
        'Note digestive comfort',
      ],
    ),
    IridologyZone(
      id: 'respiratory_zone',
      name: 'Respiratory System',
      bodySystem: 'Respiratory',
      startAngle: 2 * pi / 6,   // 2 o'clock
      endAngle: 3 * pi / 6,     // 3 o'clock
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Area linked to lungs and breathing',
      wellnessInsights: [
        'Awareness of breathing patterns',
        'Consider air quality exposure',
        'Reflect on respiratory wellness',
      ],
    ),
    // ... additional zones
  ];
}
```

**Iris Segmentation & Mapping:**

```dart
class IridologyMappingService {
  Future<IridologyAnalysis> analyzeIris(
    Uint8List irisImage,
    bool isLeftEye,
  ) async {
    // 1. Segment iris into zones
    final zones = isLeftEye 
      ? IridologyZones.leftEyeZones 
      : IridologyZones.rightEyeZones;
    
    // 2. Extract color and texture features from each zone
    final zoneAnalyses = <ZoneAnalysis>[];
    
    for (final zone in zones) {
      final zonePixels = await _extractZonePixels(irisImage, zone);
      final colorProfile = await _analyzeColorProfile(zonePixels);
      final textureFeatures = await _analyzeTexture(zonePixels);
      
      zoneAnalyses.add(ZoneAnalysis(
        zone: zone,
        colorProfile: colorProfile,
        textureFeatures: textureFeatures,
      ));
    }
    
    // 3. Generate wellness insights based on patterns
    final insights = await _generateWellnessInsights(zoneAnalyses);
    
    return IridologyAnalysis(
      zoneAnalyses: zoneAnalyses,
      insights: insights,
      timestamp: DateTime.now(),
    );
  }
  
  Future<List<Point>> _extractZonePixels(
    Uint8List irisImage,
    IridologyZone zone,
  ) async {
    // Convert to image
    final img = image_lib.decodeImage(irisImage)!;
    final centerX = img.width / 2;
    final centerY = img.height / 2;
    final maxRadius = min(centerX, centerY);
    
    final pixels = <Point>[];
    
    // Extract pixels within zone boundaries
    for (var y = 0; y < img.height; y++) {
      for (var x = 0; x < img.width; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = sqrt(dx * dx + dy * dy);
        final angle = atan2(dy, dx);
        
        final normalizedDistance = distance / maxRadius;
        
        // Check if pixel is within zone
        if (normalizedDistance >= zone.innerRadius &&
            normalizedDistance <= zone.outerRadius &&
            _isAngleInRange(angle, zone.startAngle, zone.endAngle)) {
          pixels.add(Point(x, y));
        }
      }
    }
    
    return pixels;
  }
  
  Future<List<WellnessInsight>> _generateWellnessInsights(
    List<ZoneAnalysis> analyses,
  ) async {
    final insights = <WellnessInsight>[];
    
    for (final analysis in analyses) {
      // Generate gentle, educational insights
      // NOT medical diagnoses
      insights.addAll(
        analysis.zone.wellnessInsights.map(
          (insight) => WellnessInsight(
            category: analysis.zone.bodySystem,
            title: analysis.zone.name,
            description: insight,
            reflectionPrompts: _getReflectionPrompts(analysis.zone),
          ),
        ),
      );
    }
    
    return insights;
  }
}

class WellnessInsight {
  final String category;
  final String title;
  final String description;
  final List<String> reflectionPrompts;
  
  WellnessInsight({
    required this.category,
    required this.title,
    required this.description,
    required this.reflectionPrompts,
  });
}
```

---

### 3.3 AI Art Generation Module

The Stability AI API provides text-to-image and image-to-image generation capabilities. In Flutter, API calls can be made using the HTTP package with proper authentication headers.

**Stability AI Service Implementation:**

```dart
import 'package:dio/dio.dart';

class StabilityAIService {
  final Dio _dio;
  final String _apiKey;
  
  static const String _baseUrl = 'https://api.stability.ai';
  static const String _textToImageEndpoint = 
    '/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';
  static const String _imageToImageEndpoint = 
    '/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image';
  
  StabilityAIService(this._apiKey) : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  Future<Uint8List> generateIrisArt({
    required Uint8List irisImage,
    required ArtStyle style,
    double strength = 0.75,
  }) async {
    try {
      // Convert iris image to base64
      final base64Image = base64Encode(irisImage);
      
      // Prepare request
      final formData = FormData.fromMap({
        'init_image': base64Image,
        'image_strength': strength,
        'text_prompts[0][text]': style.prompt,
        'text_prompts[0][weight]': 1.0,
        'cfg_scale': 7.5,
        'samples': 1,
        'steps': 30,
      });
      
      // Make API call
      final response = await _dio.post(
        _imageToImageEndpoint,
        data: formData,
      );
      
      if (response.statusCode == 200) {
        final artifacts = response.data['artifacts'] as List;
        final base64Result = artifacts.first['base64'] as String;
        return base64Decode(base64Result);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw ArtGenerationException('Failed to generate art: $e');
    }
  }
  
  Future<List<Uint8List>> generateMultipleVariations({
    required Uint8List irisImage,
    required List<ArtStyle> styles,
  }) async {
    final results = <Uint8List>[];
    
    for (final style in styles) {
      try {
        final art = await generateIrisArt(
          irisImage: irisImage,
          style: style,
        );
        results.add(art);
      } catch (e) {
        // Log error but continue with other styles
        print('Failed to generate ${style.name}: $e');
      }
    }
    
    return results;
  }
}

class ArtStyle {
  final String id;
  final String name;
  final String prompt;
  final String thumbnail;
  final bool isPro;
  
  const ArtStyle({
    required this.id,
    required this.name,
    required this.prompt,
    required this.thumbnail,
    this.isPro = false,
  });
  
  static const neonCyber = ArtStyle(
    id: 'neon_cyber',
    name: 'Neon Cyber',
    prompt: 'cyberpunk neon style, vibrant glowing colors, futuristic, '
            'high contrast, digital art, detailed iris patterns',
    thumbnail: 'assets/styles/neon_cyber.png',
  );
  
  static const watercolor = ArtStyle(
    id: 'watercolor',
    name: 'Watercolor Dream',
    prompt: 'soft watercolor painting, flowing colors, artistic, '
            'dreamy aesthetic, pastel tones, delicate iris details',
    thumbnail: 'assets/styles/watercolor.png',
  );
  
  static const cosmic = ArtStyle(
    id: 'cosmic',
    name: 'Cosmic Galaxy',
    prompt: 'cosmic galaxy style, nebula colors, stars, universe, '
            'space aesthetic, mystical iris with celestial patterns',
    thumbnail: 'assets/styles/cosmic.png',
    isPro: true,
  );
  
  static const geometricGold = ArtStyle(
    id: 'geometric_gold',
    name: 'Geometric Gold',
    prompt: 'geometric sacred geometry, gold foil accents, mandala patterns, '
            'luxury aesthetic, intricate iris with golden details',
    thumbnail: 'assets/styles/geometric_gold.png',
    isPro: true,
  );
  
  static const oilPainting = ArtStyle(
    id: 'oil_painting',
    name: 'Oil Painting',
    prompt: 'classical oil painting, rich textures, masterpiece quality, '
            'renaissance style, detailed iris with painterly strokes',
    thumbnail: 'assets/styles/oil_painting.png',
  );
  
  static List<ArtStyle> get allStyles => [
    neonCyber,
    watercolor,
    oilPainting,
    cosmic,
    geometricGold,
  ];
  
  static List<ArtStyle> get freeStyles => 
    allStyles.where((s) => !s.isPro).toList();
}
```

**Art Generation UI:**

```dart
class ArtGenerationScreen extends StatefulWidget {
  final IrisCaptureResult captureResult;
  
  const ArtGenerationScreen({required this.captureResult});
  
  @override
  State<ArtGenerationScreen> createState() => _ArtGenerationScreenState();
}

class _ArtGenerationScreenState extends State<ArtGenerationScreen> {
  final _artService = StabilityAIService(ConfigService.stabilityApiKey);
  ArtStyle? _selectedStyle;
  Uint8List? _generatedArt;
  bool _isGenerating = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transform Your Iris')),
      body: Column(
        children: [
          // Original iris preview
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _generatedArt == null
              ? Image.memory(widget.captureResult.leftIris)
              : Image.memory(_generatedArt!),
          ),
          
          // Style selector
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ArtStyle.allStyles.length,
              itemBuilder: (context, index) {
                final style = ArtStyle.allStyles[index];
                final isLocked = style.isPro && !UserService.isPro;
                
                return GestureDetector(
                  onTap: isLocked ? _showProUpgrade : () {
                    setState(() => _selectedStyle = style);
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedStyle == style 
                          ? Colors.blue 
                          : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            style.thumbnail,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isLocked)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.lock, color: Colors.white),
                            ),
                          ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Text(
                            style.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Generate button
          ElevatedButton(
            onPressed: _selectedStyle == null || _isGenerating 
              ? null 
              : _generateArt,
            child: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Transform'),
          ),
          
          const Spacer(),
          
          // Action buttons
          if (_generatedArt != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _remix,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Remix'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveAndShare,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _generateArt() async {
    if (_selectedStyle == null) return;
    
    setState(() => _isGenerating = true);
    
    try {
      final art = await _artService.generateIrisArt(
        irisImage: widget.captureResult.leftIris,
        style: _selectedStyle!,
      );
      
      setState(() {
        _generatedArt = art;
        _isGenerating = false;
      });
      
      // Track analytics
      AnalyticsService.logEvent('art_generated', {
        'style': _selectedStyle!.id,
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      _showError('Failed to generate art. Please try again.');
    }
  }
  
  void _remix() {
    // Regenerate with slight variation
    _generateArt();
  }
  
  Future<void> _saveAndShare() async {
    if (_generatedArt == null) return;
    
    // Save to history
    await HistoryService.saveArt(
      irisImage: widget.captureResult.leftIris,
      artImage: _generatedArt!,
      style: _selectedStyle!,
    );
    
    // Navigate to share screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareScreen(artImage: _generatedArt!),
      ),
    );
  }
}
```

---

### 3.4 Wellness Insights & Disclaimers

**CRITICAL: Legal Compliance**

The app must include prominent disclaimers stating:
- NOT a medical device
- NOT for diagnosis or treatment
- For wellness education and artistic expression only
- Users should consult healthcare professionals for medical concerns

```dart
class WellnessInsightsScreen extends StatelessWidget {
  final IridologyAnalysis analysis;
  
  const WellnessInsightsScreen({required this.analysis});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Reflections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDisclaimerDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Prominent disclaimer banner
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For wellness education only. Not medical advice.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: analysis.insights.length,
              itemBuilder: (context, index) {
                final insight = analysis.insights[index];
                return _InsightCard(insight: insight);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Important Notice'),
        content: const SingleChildScrollView(
          child: Text(
            'This app is designed for wellness education and artistic '
            'expression only.\n\n'
            'The insights provided are NOT medical diagnoses and should '
            'NOT be used to diagnose, treat, cure, or prevent any disease.\n\n'
            'Iridology is considered a complementary practice and is not '
            'validated by conventional medicine.\n\n'
            'Always consult qualified healthcare professionals for medical '
            'concerns or before making any changes to your health routine.\n\n'
            'By using this app, you acknowledge that it is for informational '
            'and creative purposes only.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final WellnessInsight insight;
  
  const _InsightCard({required this.insight});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(insight.category),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reflection Prompts:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...insight.reflectionPrompts.map(
              (prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(
                        prompt,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Digestive':
        return Icons.restaurant;
      case 'Respiratory':
        return Icons.air;
      case 'Cardiovascular':
        return Icons.favorite;
      default:
        return Icons.health_and_safety;
    }
  }
}
```

---

### 3.5 Privacy & Security Implementation

**On-Device Processing:**

```dart
class PrivacySettings {
  static const String keyStoreImages = 'store_images_locally';
  static const String keyCloudBackup = 'enable_cloud_backup';
  static const String keyAnalytics = 'enable_analytics';
  
  static Future<bool> shouldStoreImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyStoreImages) ?? false;
  }
  
  static Future<void> setStoreImages(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyStoreImages, value);
  }
}

class SecureImageStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  Future<void> saveIrisImage({
    required String id,
    required Uint8List imageData,
    bool encryptImage = true,
  }) async {
    if (!await PrivacySettings.shouldStoreImages()) {
      // User opted out of storage
      return;
    }
    
    if (encryptImage) {
      // Encrypt image data before storage
      final encryptedData = await _encryptData(imageData);
      await _secureStorage.write(
        key: 'iris_$id',
        value: base64Encode(encryptedData),
      );
    } else {
      // Store locally without cloud sync
      final file = File('${await _getLocalPath()}/iris_$id.enc');
      await file.writeAsBytes(imageData);
    }
  }
  
  Future<void> deleteAllImages() async {
    // GDPR right to erasure
    await _secureStorage.deleteAll();
    final dir = Directory(await _getLocalPath());
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
```

---

## 4. Monetization Implementation

### 4.1 In-App Purchases with RevenueCat

```dart
class SubscriptionService {
  static const String proMonthly = 'pro_monthly';
  static const String proYearly = 'pro_yearly';
  
  Future<void> initialize() async {
    await Purchases.configure(
      PurchasesConfiguration(ConfigService.revenueCatApiKey),
    );
  }
  
  Future<bool> isPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['pro']?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
  
  Future<List<Package>> getAvailablePackages() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }
  
  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      return purchaserInfo.entitlements.all['pro']?.isActive ?? false;
    } on PlatformException catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError.name) {
        // User cancelled
        return false;
      }
      rethrow;
    }
  }
  
  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }
}
```

### 4.2 Paywall UI

```dart
class PaywallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            // Benefits list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Unlock Pro Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _BenefitItem(
                    icon: Icons.palette,
                    title: 'All Art Styles',
                    subtitle: 'Access 15+ premium art styles',
                  ),
                  _BenefitItem(
                    icon: Icons.hd,
                    title: '4K Upscaling',
                    subtitle: 'Export in ultra-high resolution',
                  ),
                  _BenefitItem(
                    icon: Icons.water_drop_outlined,
                    title: 'No Watermarks',
                    subtitle: 'Share without branding',
                  ),
                  _BenefitItem(
                    icon: Icons.history,
                    title: 'Unlimited History',
                    subtitle: 'Save all your scans',
                  ),
                ],
              ),
            ),
            
            // Pricing
            FutureBuilder<List<Package>>(
              future: SubscriptionService().getAvailablePackages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                
                return Column(
                  children: snapshot.data!.map((package) {
                    return _PricingButton(package: package);
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => SubscriptionService().restorePurchases(),
              child: const Text('Restore Purchases'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Deployment Checklist

### App Store Compliance
- [ ] Medical device disclaimers in app description
- [ ] Clear labeling as "wellness education"
- [ ] Privacy policy URL
- [ ] Terms of service
- [ ] Age rating: 4+ (no medical claims)

### GDPR Compliance
- [ ] Consent flow for data collection
- [ ] Easy data export
- [ ] Easy data deletion
- [ ] Cookie/tracking consent
- [ ] Privacy policy with data processing details

### Performance Targets
- [ ] Iris capture: < 2 seconds
- [ ] Local analysis: < 1 second
- [ ] Art generation: 10-30 seconds (cloud API)
- [ ] App launch: < 3 seconds

---

## 6. Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.5.1
  
  # Camera & Images
  camera: ^0.11.0
  image_picker: ^1.0.0
  image: ^4.1.0
  
  # ML & Computer Vision
  face_detection_tflite: ^0.2.0
  tflite_flutter: ^0.10.0
  
  # HTTP & API
  dio: ^5.4.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  firebase_storage: ^11.5.0
  firebase_analytics: ^10.7.0
  
  # Payments
  purchases_flutter: ^6.20.0  # RevenueCat
  
  # UI/UX
  lottie: ^3.0.0
  cached_network_image: ^3.3.0
  fl_chart: ^0.66.0
  
  # Utilities
  path_provider: ^2.1.0
  share_plus: ^7.2.0
  permission_handler: ^11.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.0
  build_runner: ^2.4.0
```

---

## 7. Cost Estimates

### Infrastructure (Monthly)
- **Stability AI API**: 
  - ~$0.02 per generation
  - 10,000 generations/month = $200
  
- **Firebase**:
  - Spark (free): Good for first 1000 users
  - Blaze: ~$50-200/month at scale
  
- **RevenueCat**: Free up to $10k MRR

### Development Timeline
- **MVP (Weeks 1-8)**: Camera, basic detection, 2 art styles
- **Beta (Weeks 9-12)**: Full feature set, wellness insights
- **Launch (Week 13+)**: Marketing, community features

---

## 8. Next Steps

1. **Set up development environment**
   - Install Flutter SDK 3.24+
   - Configure iOS/Android emulators
   - Set up Firebase project

2. **Implement core camera flow**
   - Camera permissions
   - Iris detection with face_detection_tflite
   - Quality validation

3. **Build iridology mapping**
   - Define zone data structures
   - Implement segmentation
   - Create wellness insight templates

4. **Integrate Stability AI**
   - Sign up for API key
   - Test art generation
   - Optimize prompts for each style

5. **Design UI/UX**
   - Onboarding flow
   - Camera interface
   - Results presentation

6. **Implement monetization**
   - Set up RevenueCat
   - Create paywall
   - Configure products in App Store/Play Store

7. **Legal compliance**
   - Draft privacy policy
   - Create terms of service
   - Add disclaimers throughout app

---

## References

Sources used in this architecture:
- face_detection_tflite package documentation for iris detection capabilities
- Stability AI API integration guides for Flutter applications
- Iridology chart mapping methodologies and zone definitions

---

**Status**: Ready for implementation
**Last Updated**: November 6, 2025
