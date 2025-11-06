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

### ✅ Phase 2 - Camera & Iris Detection (COMPLETED)

Phase 2 has been successfully completed with full camera and iris detection integration:

#### Camera Integration
- **Camera Service** - Complete camera controller with all features
  - Front-facing camera initialization
  - Auto-focus and exposure controls
  - Zoom and flash mode settings
  - Image stream support for real-time processing
- **Permission Handling** - Runtime camera permission management
- **Camera Preview** - Live camera feed with Material Design UI

#### Iris Detection
- **Detection Service** - Iris landmark detection (ready for ML integration)
  - Face detection framework
  - Iris center point calculation
  - Iris radius measurement
  - Mock detection for testing (production-ready structure)
- **Quality Validation** - Detection quality checks
  - Iris size validation
  - Eye alignment verification
  - Head tilt detection

#### Image Quality Analysis
- **Sharpness Detection** - Laplacian variance method
- **Brightness Analysis** - Luminosity calculation
- **Contrast Measurement** - Standard deviation analysis
- **Glare Detection** - Overexposed pixel identification
- **Motion Blur Detection** - Edge sharpness analysis
- **Quality Metrics** - Comprehensive quality scoring (0-1 scale)

#### Iris Extraction
- **Region Extraction** - Precise iris cropping with padding
- **Image Enhancement** - Contrast and sharpness improvements
- **Normalization** - Standardized 512x512 iris images
- **Circular Masking** - Iris-focused region isolation
- **Color Histogram** - RGB distribution analysis

#### UI Components
- **Iris Camera Screen V2** - Fully integrated camera UI
  - Real-time camera preview
  - Animated guide overlay with color-coded states
  - Quality feedback messages
  - Capture button with processing states
- **Iris Guide Overlay** - Custom painted circular guide
  - Color-coded guidance (green=ready, orange=adjust, red=error)
  - Crosshair alignment aid
  - Corner framing markers
- **Result Screen** - Captured iris display
  - Quality score visualization
  - Left and right iris images
  - Detailed quality metrics
  - Accept/Retake options

#### Data Models
- **IrisCaptureResult** - Comprehensive capture result entity
- **IrisQualityMetrics** - Detailed quality metrics
- **IrisLandmarks** - Detected landmarks and coordinates
- **CaptureGuidanceState** - Camera guidance states enum

### ✅ Phase 3 - Iridology Mapping (COMPLETED)

Phase 3 has been successfully completed with full iridology analysis implementation:

### ✅ Phase 4 - AI Art Generation (COMPLETED)

Phase 4 has been successfully completed with full AI art generation integration:

### ✅ Phase 5 - Enhanced Wellness UI & History (COMPLETED)

Phase 5 has been successfully completed with comprehensive history tracking and visualization:

### ✅ Phase 6 - Advanced History Management (COMPLETED)

Phase 6 has been successfully completed with advanced analytics and data management:

#### Advanced Search System
- **Advanced Search Service** - Full-text search with multiple criteria
  - Search in tags, notes, body systems, insights
  - Advanced filtering (quality range, date range, insight count)
  - Search suggestions based on partial queries
  - Text highlighting in results
  - Group by multiple criteria (date, month, quality, etc.)
- **Search Options** - Customizable search scope
  - Tags-only search
  - Insights-only search
  - Combined search modes
- **Search Results Grouping** - Organized result display
  - Group by date, month, quality bucket
  - Group by insight count or body system
  - Group by tags

#### Backup & Restore System
- **Backup Service** - Complete data backup
  - Full history backup to JSON
  - Optional image inclusion
  - Compression support
  - Backup metadata (device info, timestamps)
- **Restore Functionality** - Data recovery
  - Merge mode (keep existing, add new)
  - Replace mode (clear and restore)
  - Validation checks
  - Progress tracking
- **Auto-Backup** - Scheduled backups
  - Configurable interval (days)
  - Minimum scan threshold
  - Maximum backup retention
  - Automatic old backup cleanup
- **Backup Management** - File organization
  - List available backups
  - Backup info display (date, size, scan count)
  - Delete old backups
  - Share backup files

#### Analytics Dashboard
- **Overview Cards** - Key metrics at a glance
  - Total scans count
  - Total insights generated
  - Average quality score
  - Art pieces created
- **Quality Trend Chart** - Line graph visualization
  - Quality score over time
  - Trend line display
  - Data point indicators
- **Insights Trend** - Bar chart visualization
  - Insights count per scan
  - Visual comparison over time
- **Body Systems Breakdown** - Horizontal bar chart
  - Top 5 analyzed systems
  - Frequency counts
  - Percentage bars
- **Activity Heatmap** - Day of week analysis
  - Scan distribution by weekday
  - Visual bar chart
  - Pattern identification
- **Art Generation Stats** - Circular progress
  - Percentage of scans with art
  - Visual circular indicator
  - Ratio display
- **Time Range Filter** - Flexible time periods
  - Last 7 days
  - Last 30 days
  - Last 90 days
  - Last year
  - All time

#### Data Privacy & Management
- **Local-First Architecture** - Privacy by design
  - All data stored locally with Hive
  - No cloud sync required
  - User controls all data
- **Data Export** - Complete data portability
  - Export to JSON, CSV, or Text
  - Include or exclude images
  - Full metadata preservation
- **Data Cleanup** - Storage management
  - Selective scan deletion
  - Batch deletion support
  - Clear all history option
  - Confirmation dialogs

#### Wellness Trends
- **Quality Tracking** - Monitor scan quality over time
- **Insight Growth** - Track wellness insights accumulation
- **System Coverage** - See which body systems are analyzed most
- **Activity Patterns** - Identify scanning habits and patterns

#### History Storage System
- **History Storage Service** - Local persistence with Hive
  - CRUD operations for scan history
  - Filter and sort capabilities
  - Tag management system
  - Statistics tracking
  - Export functionality
  - Automatic cleanup
- **Scan History Entity** - Complete history data model
  - Iris images (left/right)
  - Analysis results
  - Art generation references
  - Metadata (quality, device, version)
  - Tags and notes

#### Interactive Iris Map
- **Interactive Zone Map Widget** - Tap-able zone visualization
  - Real-time iris image display
  - Zone overlays with color coding
  - Tap detection for zone selection
  - Heatmap mode (significance-based coloring)
  - Label mode with abbreviations
  - Selected zone highlighting
  - Animated interactions
- **Custom Painter** - Polar coordinate zone rendering
  - Arc-based zone drawing
  - Gradient fills
  - Border animations
  - Performance-optimized rendering

#### Zone Detail View
- **Zone Detail Screen** - Comprehensive zone analysis
  - Large zone visualization
  - Significance score with progress bar
  - Color profile breakdown (RGB)
  - Texture metrics (uniformity, density, patterns)
  - Brightness and saturation indicators
  - Zone observations list
  - Wellness reflection prompts
  - Technical details (coordinates, ranges)
  - Zone info dialogs

#### Historical Tracking
- **History Timeline Screen** - Chronological scan timeline
  - Vertical timeline with date headers
  - Scan cards with preview images
  - Quality scores and insight counts
  - Art generation indicators
  - Swipe-to-delete functionality
  - Sort options (date, quality, insights)
  - Statistics summary banner
  - Empty state with guidance
  - Pull-to-refresh support
- **Timeline Statistics** - Comprehensive metrics
  - Total scans count
  - Average quality score
  - Total insights generated
  - Art generation rate
  - Date range tracking

#### Scan Comparison
- **Comparison Screen** - Side-by-side analysis
  - 2-3 scan comparison support
  - Iris image comparison
  - Quality metrics comparison
  - Insights count trends
  - Body systems coverage matrix
  - Timeline chart with trend lines
  - Trend indicators (up/down/neutral)
  - Quality score visualization
  - Progress tracking

#### Export System
- **Export Service** - Multiple format support
  - JSON export (structured data)
  - CSV export (spreadsheet format)
  - Text export (readable reports)
  - Share integration
  - Temporary file management
- **Report Generation** - Comprehensive reports
  - Full analysis text reports
  - Insight summaries
  - Body system breakdown
  - Zone analysis details
  - Disclaimers included
  - Timestamp and metadata

#### Enhanced Insights UI
- **Map/List Toggle** - Dual viewing modes
  - Interactive map view
  - Traditional list view
  - Mode switching button
  - Persistent selection
- **Zone Navigation** - Tap-to-navigate
  - Direct zone detail navigation
  - Zone selection feedback
  - Smooth transitions
  - Context preservation

#### Data Models
- **ScanHistoryEntry** - Complete scan record
- **ScanMetadata** - Device and quality info
- **HistoryFilter** - Advanced filtering
- **HistoryStatistics** - Aggregated metrics
- **ExportFormat** - Export configuration

#### Stability AI Integration
- **AI Art Service** - Stability AI API integration
  - Image-to-image transformation
  - Style preset mapping
  - Quality presets (free vs pro)
  - Mock generation for testing
  - Comprehensive error handling
- **API Configuration** - Configurable API settings
  - API key management
  - Timeout configuration
  - Base URL customization
  - Caching options

#### Art Generation Features
- **Art Generation Request** - Parameterized generation
  - Strength control (0.0-1.0)
  - Seed for reproducibility
  - Step count for quality control
  - Free and Pro quality presets
- **Art Generation Result** - Complete result entity
  - Success/processing/failed states
  - Generation time tracking
  - Original and generated image storage
  - Error message handling

#### Art Style Selector
- **Style Selector Screen** - Professional style selection UI
  - Grid layout with 12 art styles
  - Free styles section (4 styles)
  - Pro styles section (8 premium styles)
  - Style preview cards with gradients
  - Pro badge indicators
  - Style locking for free users
  - Pro upgrade prompts
- **Style Information** - Detailed style metadata
  - Style name and description
  - AI prompt display
  - Color-coded style cards
  - Icon-based style representation

#### Art Result Display
- **Art Result Screen** - Generated art showcase
  - Full-screen art display
  - Generation time display
  - Style information card
  - Before/After comparison
  - Save to gallery functionality
  - Share functionality
  - Style info dialog
  - "Try Another Style" option
- **Save & Share** - Export capabilities
  - Save to device storage
  - Share via system share sheet
  - Timestamped file naming
  - Professional attribution

#### Integration Points
- **Result Screen Integration** - Direct art generation
  - "Create Art" button on result screen
  - Skip analysis option
  - Direct navigation to style selector
- **Wellness Insights Integration** - Post-analysis art creation
  - Floating action button
  - Gradient CTA banner
  - Seamless navigation flow
  - Iris image propagation

#### Free vs Pro Gating
- **Feature Gating** - Subscription-based access
  - 4 free styles available
  - 8 pro styles locked
  - Lock indicators on pro styles
  - Upgrade prompts and dialogs
  - Pro badge display
  - Quality tier differences (20 vs 50 steps)

#### Data Models
- **ArtGenerationResult** - Complete result entity
- **ArtGenerationRequest** - Request parameters
- **ArtGenerationConfig** - Service configuration
- **ArtGenerationStatus** - Generation state enum

#### Iridology Analysis System
- **Iridology Mapping Service** - Main analysis orchestrator
  - Complete iris-to-zone mapping
  - Zone extraction using polar coordinates
  - Wellness insight generation
  - Confidence scoring system
- **Iris Segmentation Service** - Polar coordinate mapping
  - Extract pixels for specific zones
  - Zone mask generation
  - Bounding box calculations
  - Zone visualization

#### Color Analysis
- **Color Analysis Service** - RGB and HSV analysis
  - RGB to HSV color space conversion
  - Iris color classification (Blue, Green, Brown, Hazel, Gray, Amber)
  - Color variation detection
  - Secondary color identification
  - Color histogram generation
  - Overall iris color profiling

#### Analysis Features
- **Zone Analysis** - Per-zone detailed analysis
  - Color profile per zone (RGB, HSV, brightness, saturation)
  - Texture features (uniformity, density, patterns)
  - Observation generation
  - Significance scoring (0-1 scale)
- **Wellness Insights** - Educational reflections
  - Body system mapping (10+ systems)
  - Reflection prompts per zone
  - Insight categorization (Nutrition, Activity, Stress, etc.)
  - Confidence levels

#### UI Components
- **Wellness Insights Screen** - Professional insights display
  - Disclaimer banner (GDPR/MHRA compliant)
  - Analysis summary card
  - Expandable insight cards
  - Category-based color coding
  - Confidence indicators
- **Result Screen Integration** - Seamless flow
  - Loading state during analysis
  - Error handling
  - Navigation to insights

#### Data Models
- **IridologyAnalysis** - Complete analysis result
- **ZoneAnalysis** - Per-zone analysis data
- **ColorProfile** - Color characteristics
- **IrisColorProfile** - Overall iris color
- **TextureFeatures** - Pattern analysis
- **WellnessInsight** - Generated insights
- **InsightCategory** - Categorization enum
- **IrisColorType** - Color classification enum
- **PatternType** - Texture pattern enum

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

### ✅ Phase 7 - Monetization & Subscriptions (COMPLETED)

Phase 7 has been successfully completed with mock subscription system for testing:

#### Subscription System
- **Mock Subscription Service** - Testing-ready subscription implementation
  - Simulates real purchase flow with delays
  - 7-day trial support with eligibility tracking
  - SharedPreferences persistence
  - Purchase, restore, and cancel operations
  - Testing utilities for instant pro activation
- **Subscription Domain Entities** - Complete subscription models
  - SubscriptionStatus (free/trial/pro states)
  - SubscriptionProduct (monthly/yearly pricing)
  - Entitlements (feature access control)
  - PurchaseResult (transaction handling)
- **State Management** - Riverpod providers
  - Real-time subscription monitoring (polls every 30 seconds)
  - StreamProvider for status updates
  - Purchase/restore/cancel action providers
  - Automatic UI refresh on subscription changes

#### Monetization UI
- **Paywall Screen** - Beautiful pricing display
  - Hero section with feature highlights
  - Product selection (Monthly $4.99, Yearly $39.99)
  - "Save 33%" badge on yearly plan
  - 6 feature highlights with icons
  - "Start Free Trial" CTA button
  - Restore purchases option
  - Terms and privacy links
- **Subscription Management Screen** - Pro user dashboard
  - Active subscription status card
  - Trial warning (when ending within 2 days)
  - Plan details (type, renewal date)
  - Billing information display
  - Cancel subscription with confirmation
  - Restore purchases functionality
  - Debug section (development only)

#### Feature Gating System
- **FeatureGate Utility** - Centralized access control
  - isPro() - Check subscription status
  - isFeatureUnlocked() - Check specific features
  - requiresPro() - Show paywall if needed
  - showProDialog() - Upgrade prompt
  - ProFeature enum (8 features)
  - ProBadge widget (3 styles)
  - LockedFeatureOverlay widget
- **Pro Features Locked** - Free tier limitations
  - 8 pro art styles locked (Cosmic Galaxy, Geometric Gold, etc.)
  - History limited to 10 most recent scans
  - Advanced analytics dashboard locked
  - CSV and Text export formats locked (JSON only for free)
  - Upgrade banners and prompts throughout app

#### Free vs Pro Features
- **Free Tier**
  - 4 basic art styles (Neon Cyber, Watercolor, Oil Painting, Minimalist)
  - Last 10 scans in history
  - Basic history timeline
  - JSON export only
  - Quality tracking
- **Pro Tier ($4.99/month or $39.99/year)**
  - All 12 art styles including 8 premium styles
  - Unlimited scan history
  - Advanced analytics dashboard with charts
  - All export formats (JSON, CSV, Text)
  - 4K high-resolution exports
  - No watermarks
  - Priority support
  - Advanced search

#### Testing Features
- **Mock Purchase Flow** - No real payment required
  - Simulates 2-second purchase delay
  - Success/failure/cancellation handling
  - Trial eligibility checking
  - Subscription expiration handling
- **Debug Actions** (Development only)
  - Activate Pro for 30 days instantly
  - Start 7-day trial
  - Reset to free tier
  - Test all subscription states

## Development Phases

- [x] **Phase 1** - Initial Setup (COMPLETED)
- [x] **Phase 2** - Camera & Iris Detection (COMPLETED)
- [x] **Phase 3** - Iridology Mapping (COMPLETED)
- [x] **Phase 4** - AI Art Generation (COMPLETED)
- [x] **Phase 5** - Enhanced Wellness UI & History (COMPLETED)
- [x] **Phase 6** - Advanced History Management (COMPLETED)
- [x] **Phase 7** - Monetization & Subscriptions (COMPLETED)
- [ ] **Phase 8** - Social Sharing & Community

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
- ✅ Phase 2: Camera Implementation
- ✅ Phase 3: Iridology Mapping
- ✅ Phase 4: AI Art Integration
- ✅ Phase 5: Enhanced Wellness UI & History
- ✅ Phase 6: Advanced History Management
- ✅ Phase 7: Monetization & Subscriptions

### Q2 2025

### Q3 2025
- 🔄 Phase 8: Social Features
- 🔄 Beta Testing & Polish

### Q4 2025
- 🔄 App Store Launch
- 🔄 Marketing Campaign
- 🔄 Community Features

## Version History

### v0.7.0 (Current) - Phase 7 Complete
- ✅ Mock subscription service for testing
- ✅ Subscription domain entities (Status, Product, Entitlements)
- ✅ Riverpod state management for subscriptions
- ✅ Paywall screen with pricing display
- ✅ Subscription management screen
- ✅ Feature gating utility (FeatureGate)
- ✅ Pro badge and locked overlay widgets
- ✅ 8 pro art styles gated
- ✅ History limited to 10 scans for free users
- ✅ Advanced analytics locked for free users
- ✅ Export formats limited (JSON only for free)
- ✅ Debug actions for testing subscription states
- ✅ 7-day trial support
- ✅ Trial warning notifications

### v0.6.0 - Phase 6 Complete
- ✅ Advanced search service with full-text search
- ✅ Backup and restore functionality
- ✅ Analytics dashboard with charts
- ✅ Quality trend visualization (line chart)
- ✅ Insights trend visualization (bar chart)
- ✅ Body systems breakdown analysis
- ✅ Activity heatmap by weekday
- ✅ Art generation statistics
- ✅ Time range filtering (week, month, 90 days, year, all)
- ✅ Search suggestions and text highlighting
- ✅ Auto-backup with configurable settings

### v0.5.0 - Phase 5 Complete
- ✅ Interactive iris zone map with tap navigation
- ✅ Zone detail screen with comprehensive analysis
- ✅ History storage service with Hive
- ✅ Historical tracking timeline screen
- ✅ Scan comparison view (2-3 scans)
- ✅ Export service (JSON, CSV, Text)
- ✅ Map/List toggle in wellness insights
- ✅ Filter and sort history
- ✅ Tag management system
- ✅ Statistics dashboard

### v0.4.0 - Phase 4 Complete
- ✅ Stability AI integration for art generation
- ✅ Art style selector with 12 styles (4 free, 8 pro)
- ✅ Image-to-image generation service
- ✅ Art result screen with save/share
- ✅ Free vs Pro style gating
- ✅ Integration with result and insights screens
- ✅ Mock generation for testing
- ✅ Quality presets (free 20 steps, pro 50 steps)

### v0.3.0 - Phase 3 Complete
- ✅ Complete iridology mapping system
- ✅ Polar coordinate zone segmentation
- ✅ RGB/HSV color analysis per zone
- ✅ Texture and pattern analysis
- ✅ Wellness insight generation
- ✅ Professional insights UI with disclaimers
- ✅ 10+ body system mappings
- ✅ Category-based insight organization

### v0.2.0 - Phase 2 Complete
- ✅ Full camera integration with live preview
- ✅ Iris detection service (ML-ready structure)
- ✅ Comprehensive image quality analysis
- ✅ Iris extraction and processing
- ✅ Result screen with quality metrics
- ✅ Animated guide overlay with real-time feedback

### v0.1.0 - Phase 1 Complete
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

*Last Updated: November 6, 2025 - Phase 6 Complete*