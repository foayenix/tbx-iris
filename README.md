# Iris - Wellness & AI Art App

Transform your iris into stunning digital art while exploring wellness insights based on traditional iridology.

## Overview

Iris is a Flutter mobile app that combines:
- **Iris Photography** - Guided camera capture with quality checks
- **Iridology Wellness** - Educational insights based on traditional iridology
- **AI Art Generation** - Transform your iris into beautiful artwork using Stability AI
- **Privacy First** - On-device processing with optional cloud features

⚠️ **Important:** This app is for wellness education and artistic expression only. NOT a medical device.

## Project Status

### ✅ Phase 1 - Initial Setup (COMPLETED)

Phase 1 has been successfully completed with the following implementations:

#### Project Structure
- Complete Flutter project structure with feature-first organization
- Configured folder hierarchy following clean architecture principles
- Set up core constants, theme, and configuration files

#### Dependencies Configured
- State management: flutter_riverpod
- Camera & Images: camera, image_picker, image
- HTTP: dio (for Stability AI API)
- Storage: hive, hive_flutter, flutter_secure_storage, shared_preferences
- UI: lottie, cached_network_image
- Utilities: permission_handler, share_plus

#### Core Features Implemented
- **App Entry Point** (`main.dart`) with theme configuration
- **Onboarding Flow** with legal disclaimers and GDPR compliance
- **Iridology Zones** - Complete zone definitions for both eyes
- **Art Styles** - 12 art styles (4 free, 8 pro) with AI prompts
- **Wellness Disclaimers** - Full legal compliance texts
- **Camera Screen** - UI structure ready for Phase 2 integration

#### Platform Configuration
- **iOS**: Info.plist with camera and photo library permissions
- **Android**: AndroidManifest.xml with camera, storage, and internet permissions
- Build configurations for both platforms

#### Legal & Compliance
- Comprehensive wellness disclaimers (GDPR, MHRA compliant)
- First-time user agreement flow
- Educational framing throughout
- Privacy-first approach documented

## Documentation

- **[IRIS_APP_TECHNICAL_ARCHITECTURE.md](./IRIS_APP_TECHNICAL_ARCHITECTURE.md)** - Complete technical architecture
- **[QUICK_START_GUIDE.md](./QUICK_START_GUIDE.md)** - Step-by-step implementation guide
- **[iris_app_example_code.dart](./iris_app_example_code.dart)** - Reference code examples

## Getting Started

### Prerequisites

- Flutter SDK 3.5+ (when running on a machine with Flutter installed)
- Dart 3.5+
- iOS 12+ / Android 21+
- Xcode 15+ (for iOS development)
- Android Studio (for Android development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/tbx-iris.git
cd tbx-iris
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API keys (for Phase 4 - Art Generation):
```bash
# Run with environment variables
flutter run --dart-define=STABILITY_API_KEY=your_key_here
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── constants/           # Iridology zones, art styles, disclaimers
│   ├── theme/              # App theme configuration
│   ├── config/             # API configuration
│   └── utils/              # Utility functions
├── features/
│   ├── onboarding/         # Onboarding flow with disclaimers
│   ├── camera/             # Iris capture screen (Phase 2)
│   ├── iris_analysis/      # Iridology mapping (Phase 3)
│   ├── art_generation/     # AI art generation (Phase 4)
│   ├── wellness/           # Wellness insights (Phase 5)
│   ├── history/            # Scan history (Phase 6)
│   └── profile/            # User profile & settings
└── main.dart               # App entry point
```

## Next Steps - Phase 2

Phase 2 will implement:
- Camera integration with `camera` package
- Face detection for iris localization
- Real-time quality checks (sharpness, lighting, focus)
- Iris region extraction from both eyes
- Navigation to analysis screen

See [QUICK_START_GUIDE.md](./QUICK_START_GUIDE.md) for detailed implementation steps.

## Development Phases

- [x] **Phase 1** - Initial Setup (COMPLETED)
- [ ] **Phase 2** - Camera & Iris Detection
- [ ] **Phase 3** - Iridology Mapping
- [ ] **Phase 4** - AI Art Generation
- [ ] **Phase 5** - Wellness Insights UI
- [ ] **Phase 6** - History & Tracking
- [ ] **Phase 7** - Monetization
- [ ] **Phase 8** - Social Sharing

## Key Features

### Free Features
- Iris photography with guided overlay
- Basic wellness reflections (3 body systems)
- 4 free art styles (Neon Cyber, Watercolor, Oil Painting, Minimalist)
- Save up to 10 scans locally
- Basic history view

### Pro Features (Planned)
- All 12 art styles including Cosmic Galaxy, Geometric Gold, etc.
- 4K high-resolution art export
- No watermarks on generated art
- Unlimited scan history with cloud backup
- Advanced wellness insights (all body systems)
- Comparison view for tracking changes
- Priority support

## Technology Stack

- **Framework**: Flutter 3.5+
- **State Management**: Riverpod 2.x
- **Local Storage**: Hive 2.x
- **Camera**: Flutter camera package
- **ML/Vision**: Face detection (TensorFlow Lite)
- **AI Art**: Stability AI REST API
- **Analytics**: Firebase Analytics (optional)
- **Payments**: RevenueCat (planned)

## Legal & Compliance

### Health Disclaimer
This app is designed for wellness education and artistic expression purposes only. It is NOT a medical device and should NOT be used for medical diagnosis or treatment. Always consult qualified healthcare professionals for medical concerns.

### Privacy
- On-device iris detection and analysis by default
- Optional cloud processing for AI art generation
- No personal health data collected for analytics
- Full GDPR compliance with data export and deletion
- Encrypted local storage for sensitive data

### Licenses
- App Code: MIT License (or your chosen license)
- Dependencies: See individual package licenses
- AI Models: Subject to Stability AI terms of use

## Contributing

This is a proprietary project. For questions or contributions, please contact the development team.

## Support

For technical questions:
1. Review the technical architecture document
2. Check the Quick Start Guide
3. Examine the example code reference

## Roadmap

### Q1 2025
- ✅ Phase 1: Project Setup
- 🔄 Phase 2: Camera Implementation
- 🔄 Phase 3: Iridology Mapping

### Q2 2025
- 🔄 Phase 4: AI Art Integration
- 🔄 Phase 5: Wellness UI
- 🔄 Phase 6: History & Tracking

### Q3 2025
- 🔄 Phase 7: Monetization
- 🔄 Phase 8: Social Features
- 🔄 Beta Testing & Launch Prep

### Q4 2025
- 🔄 App Store Launch
- 🔄 Marketing Campaign
- 🔄 Community Features

## Version History

### v0.1.0 (Current) - Phase 1 Complete
- ✅ Project structure created
- ✅ Core constants and configurations
- ✅ Onboarding flow with disclaimers
- ✅ Platform permissions configured
- ✅ Theme and styling implemented
- ✅ Camera screen UI structure

## Contact

- Project Repository: https://github.com/foayenix/tbx-iris
- Issues: Please use GitHub Issues for bug reports

---

**Built with ❤️ using Flutter**

*Last Updated: November 6, 2025*