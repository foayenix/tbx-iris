# Iris App - Quick Start Implementation Guide

## Overview
This guide will help you get started building the Iris wellness and art app in Flutter. Follow these steps to set up your development environment and implement the core features.

---

## Phase 1: Environment Setup (Day 1)

### 1.1 Install Flutter SDK
```bash
# macOS
brew install flutter

# Or download from: https://docs.flutter.dev/get-started/install

# Verify installation
flutter doctor
```

### 1.2 Create New Project
```bash
flutter create iris_app
cd iris_app
```

### 1.3 Update pubspec.yaml
Replace your `pubspec.yaml` dependencies with:

```yaml
name: iris_app
description: Iris wellness and AI art generation app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.5.1
  
  # Camera & Images
  camera: ^0.11.0+2
  image_picker: ^1.0.7
  image: ^4.1.7
  
  # ML & Computer Vision
  face_detection_tflite: ^0.2.0
  
  # HTTP & API
  dio: ^5.4.3
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.2
  
  # UI/UX
  lottie: ^3.1.0
  cached_network_image: ^3.3.1
  
  # Utilities
  permission_handler: ^11.3.0
  share_plus: ^7.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.8

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/styles/
    - assets/animations/
```

### 1.4 Install Dependencies
```bash
flutter pub get
```

### 1.5 Configure Platform-Specific Permissions

**iOS (ios/Runner/Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture your iris image</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to save your iris art</string>
```

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />
```

---

## Phase 2: Project Structure Setup (Day 1-2)

### 2.1 Create Folder Structure
```bash
mkdir -p lib/core/{constants,theme,utils,errors}
mkdir -p lib/features/{camera,iris_analysis,art_generation,wellness,history,profile}/{data,domain,presentation}
mkdir -p lib/features/camera/{data/models,domain/entities,presentation/screens}
mkdir -p lib/features/iris_analysis/{data/services,domain/entities,presentation/screens}
mkdir -p lib/features/art_generation/{data/services,domain/entities,presentation/screens}
mkdir -p assets/{images,styles,animations}
```

### 2.2 Copy Core Files
Copy the example code files from `iris_app_example_code.dart` into your project:

1. **IrisCameraScreen**: `lib/features/camera/presentation/screens/iris_camera_screen.dart`
2. **IridologyZones**: `lib/core/constants/iridology_zones.dart`
3. **ArtStyles**: `lib/core/constants/art_styles.dart`
4. **WellnessDisclaimer**: `lib/features/wellness/domain/wellness_disclaimer.dart`

---

## Phase 3: Core Feature Implementation (Days 3-10)

### 3.1 Implement Main App Entry

**lib/main.dart:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  runApp(
    const ProviderScope(
      child: IrisApp(),
    ),
  );
}

class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iris - Wellness & Art',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
```

### 3.2 Create Onboarding with Disclaimer

**lib/features/onboarding/onboarding_screen.dart:**
```dart
import 'package:flutter/material.dart';
import '../wellness/domain/wellness_disclaimer.dart';
import '../camera/presentation/screens/iris_camera_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _hasAcceptedTerms = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Iris',
      description: 'Transform your iris into stunning digital art while '
                   'exploring wellness insights',
      image: 'assets/images/onboarding1.png',
    ),
    OnboardingPage(
      title: 'Capture Your Iris',
      description: 'Our guided camera makes it easy to capture a clear '
                   'photo of your eye',
      image: 'assets/images/onboarding2.png',
    ),
    OnboardingPage(
      title: 'Wellness Reflections',
      description: 'Receive gentle wellness insights based on traditional '
                   'iridology principles',
      image: 'assets/images/onboarding3.png',
    ),
    OnboardingPage(
      title: 'Create Beautiful Art',
      description: 'Turn your iris into unique artwork with AI-powered '
                   'style transformations',
      image: 'assets/images/onboarding4.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Disclaimer checkbox (on last page)
            if (_currentPage == _pages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CheckboxListTile(
                  value: _hasAcceptedTerms,
                  onChanged: (value) {
                    setState(() => _hasAcceptedTerms = value ?? false);
                  },
                  title: const Text(
                    'I understand this app is for wellness education '
                    'and creative expression, not medical diagnosis',
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (_currentPage == _pages.length - 1 && 
                                !_hasAcceptedTerms)
                        ? null
                        : () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _completeOnboarding();
                            }
                          },
                    child: Text(
                      _currentPage == _pages.length - 1 
                          ? 'Get Started' 
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for image
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove_red_eye,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Save that user has completed onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Navigate to home or camera
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const IrisCameraScreen(),
        ),
      );
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}
```

### 3.3 Implement Stability AI Service

**lib/features/art_generation/data/services/stability_ai_service.dart:**
```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/constants/art_styles.dart';

class StabilityAIService {
  final Dio _dio;
  final String _apiKey;
  
  static const String _baseUrl = 'https://api.stability.ai';
  
  StabilityAIService(this._apiKey) : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  Future<Uint8List> generateIrisArt({
    required Uint8List irisImage,
    required ArtStyle style,
    double imageStrength = 0.35,
  }) async {
    try {
      // Prepare form data
      final formData = FormData.fromMap({
        'init_image': MultipartFile.fromBytes(
          irisImage,
          filename: 'iris.jpg',
        ),
        'image_strength': imageStrength,
        'init_image_mode': 'IMAGE_STRENGTH',
        'text_prompts[0][text]': style.prompt,
        'text_prompts[0][weight]': 1.0,
        'cfg_scale': style.cfgScale,
        'samples': 1,
        'steps': 30,
      });
      
      if (style.negativePrompt.isNotEmpty) {
        formData.fields.add(
          MapEntry('text_prompts[1][text]', style.negativePrompt),
        );
        formData.fields.add(
          MapEntry('text_prompts[1][weight]', '-1.0'),
        );
      }

      // Make API request
      final response = await _dio.post(
        '/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final artifacts = data['artifacts'] as List;
        
        if (artifacts.isEmpty) {
          throw Exception('No image generated');
        }
        
        final base64Image = artifacts.first['base64'] as String;
        return base64Decode(base64Image);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate art: $e');
    }
  }
  
  Future<List<Uint8List>> generateMultipleStyles({
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
        print('Failed to generate ${style.name}: $e');
        // Continue with other styles
      }
    }
    
    return results;
  }
}
```

---

## Phase 4: Testing & Running (Day 11)

### 4.1 Test on Emulator
```bash
# Start iOS simulator
open -a Simulator

# Or start Android emulator
flutter emulators --launch <emulator_id>

# Run app
flutter run
```

### 4.2 Test on Real Device
```bash
# iOS (requires Apple Developer account)
flutter run --release

# Android
flutter run --release
```

### 4.3 Debug Common Issues

**Issue: Camera not working**
- Check permissions in Info.plist/AndroidManifest.xml
- Request permissions at runtime using permission_handler

**Issue: Face detection not working**
- Ensure TensorFlow Lite models are included
- Check that image format is supported (JPEG)

**Issue: API calls failing**
- Verify Stability AI API key is valid
- Check network connectivity
- Ensure API endpoints are correct

---

## Phase 5: API Keys Configuration

### 5.1 Get Stability AI API Key
1. Visit: https://platform.stability.ai/
2. Create account and generate API key
3. Store securely (DO NOT commit to Git)

### 5.2 Create Config File

**lib/core/config/api_config.dart:**
```dart
class ApiConfig {
  // IMPORTANT: Never commit API keys to Git
  // Use environment variables or secure storage in production
  
  static const String stabilityApiKey = String.fromEnvironment(
    'STABILITY_API_KEY',
    defaultValue: 'your_api_key_here',
  );
}
```

### 5.3 Use Environment Variables
```bash
# Run with API key
flutter run --dart-define=STABILITY_API_KEY=sk-your-key-here
```

---

## Phase 6: Build for Production

### 6.1 Update App Information

**android/app/build.gradle:**
```gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.irisapp"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

**ios/Runner/Info.plist:**
```xml
<key>CFBundleName</key>
<string>Iris</string>
<key>CFBundleDisplayName</key>
<string>Iris</string>
```

### 6.2 Build Release APK (Android)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 6.3 Build IPA (iOS)
```bash
flutter build ios --release
# Then archive in Xcode and upload to App Store Connect
```

---

## Phase 7: App Store Submission Checklist

### 7.1 Required Assets
- [ ] App icon (1024x1024 PNG)
- [ ] Screenshots (various device sizes)
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support URL
- [ ] Marketing website (optional)

### 7.2 App Store Description Template

**Title:** Iris - Wellness Art & Exploration

**Subtitle:** Transform Your Iris into Beautiful Art

**Description:**
```
Discover the beauty of your unique iris through artistic expression and gentle wellness reflection.

🎨 CREATE STUNNING ART
Transform your iris into beautiful digital artwork with AI-powered style generators. Choose from watercolor, neon cyber, cosmic galaxy, and more!

✨ WELLNESS REFLECTIONS
Explore wellness insights inspired by traditional iridology principles. Track your personal wellness journey over time.

🔒 PRIVACY FIRST
Your images are processed securely with on-device options. We prioritize your privacy and data security.

IMPORTANT NOTICE:
This app is for wellness education and creative expression only. It is NOT a medical device and should NOT be used for medical diagnosis or treatment. Always consult qualified healthcare professionals for medical concerns.

PRO FEATURES (Optional):
• Unlock all premium art styles
• 4K high-resolution exports
• No watermarks on creations
• Unlimited scan history
• Priority support

Download now and discover the art in your eyes!
```

### 7.3 Keywords
iris art, wellness, iridology, eye photography, AI art, digital art, health tracking, wellness journal

### 7.4 Age Rating
**4+** (Educational/wellness content with proper disclaimers)

---

## Next Steps After MVP

1. **Add Firebase Analytics** - Track user behavior
2. **Implement Crash Reporting** - Use Sentry or Firebase Crashlytics
3. **Add Social Sharing** - Share to Instagram, Twitter, etc.
4. **Build Community Features** - Weekly challenges, gallery
5. **Integrate Payment System** - RevenueCat for subscriptions
6. **Create Merchandise Store** - Printful/Printify integration
7. **Add Journaling Features** - Wellness diary and habit tracking
8. **Implement Cloud Sync** - Firebase for cross-device sync

---

## Helpful Resources

### Documentation
- Flutter Docs: https://docs.flutter.dev
- Stability AI API: https://platform.stability.ai/docs
- face_detection_tflite: https://pub.dev/packages/face_detection_tflite

### Learning Resources
- Flutter Codelabs: https://docs.flutter.dev/codelabs
- DartPad (online editor): https://dartpad.dev
- Flutter YouTube Channel: youtube.com/@flutterdev

### Community
- Flutter Discord: discord.gg/flutter
- Reddit r/FlutterDev: reddit.com/r/FlutterDev
- Stack Overflow Flutter tag: stackoverflow.com/questions/tagged/flutter

---

## Estimated Timeline

- **Week 1-2**: Setup + Camera capture + Iris detection
- **Week 3-4**: Iridology mapping + Wellness insights
- **Week 5-6**: AI art generation integration
- **Week 7-8**: UI polish + History/Profile features
- **Week 9-10**: Testing + Bug fixes
- **Week 11-12**: Beta testing + Marketing prep
- **Week 13+**: App Store submission + Launch

---

## Support

For questions or issues:
1. Check the technical architecture document
2. Review example code implementations
3. Search Flutter documentation
4. Ask on Flutter community forums

Good luck building your Iris app! 🌈👁️
