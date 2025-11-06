// lib/core/config/api_config.dart
// API configuration and keys
// IMPORTANT: Never commit actual API keys to Git!

/// API configuration for external services
/// Use environment variables or secure storage in production
class ApiConfig {
  // ============================================================
  // Stability AI Configuration
  // ============================================================

  /// Stability AI API Key
  /// Get yours at: https://platform.stability.ai/
  /// IMPORTANT: Use --dart-define for production builds
  static const String stabilityApiKey = String.fromEnvironment(
    'STABILITY_API_KEY',
    defaultValue: '', // Empty by default - must be provided
  );

  static const String stabilityBaseUrl = 'https://api.stability.ai';
  static const String stabilityApiVersion = 'v1';

  /// Stability AI endpoints
  static const String stabilityTextToImageEndpoint =
      '/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';
  static const String stabilityImageToImageEndpoint =
      '/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image';

  // ============================================================
  // Firebase Configuration (Optional)
  // ============================================================

  /// Enable Firebase services (Analytics, Storage, etc.)
  static const bool enableFirebase = bool.fromEnvironment(
    'ENABLE_FIREBASE',
    defaultValue: false,
  );

  // Firebase config will be in google-services.json (Android)
  // and GoogleService-Info.plist (iOS)

  // ============================================================
  // RevenueCat Configuration (for in-app purchases)
  // ============================================================

  /// RevenueCat API Key
  /// Get yours at: https://www.revenuecat.com/
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '', // Empty by default
  );

  // Platform-specific keys
  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: '',
  );

  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: '',
  );

  // ============================================================
  // Analytics Configuration
  // ============================================================

  /// Enable analytics tracking
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  // ============================================================
  // Feature Flags
  // ============================================================

  /// Enable pro features (for testing)
  static const bool enableProFeatures = bool.fromEnvironment(
    'ENABLE_PRO_FEATURES',
    defaultValue: false,
  );

  /// Enable debug mode
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );

  // ============================================================
  // API Timeouts & Limits
  // ============================================================

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration artGenerationTimeout = Duration(seconds: 60);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ============================================================
  // Image Processing Limits
  // ============================================================

  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int recommendedImageWidth = 1024;
  static const int recommendedImageHeight = 1024;
  static const int irisExtractionSize = 512; // Size for iris region extraction

  // ============================================================
  // Storage Limits
  // ============================================================

  static const int maxLocalHistoryItems = 50; // Free tier
  static const int maxProHistoryItems = 1000; // Pro tier
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB

  // ============================================================
  // Validation Methods
  // ============================================================

  /// Check if Stability AI is configured
  static bool get isStabilityConfigured => stabilityApiKey.isNotEmpty;

  /// Check if RevenueCat is configured
  static bool get isRevenueCatConfigured => revenueCatApiKey.isNotEmpty;

  /// Check if Firebase is configured
  static bool get isFirebaseConfigured => enableFirebase;

  /// Get configuration status for debugging
  static Map<String, dynamic> get configStatus => {
        'stability_configured': isStabilityConfigured,
        'revenuecat_configured': isRevenueCatConfigured,
        'firebase_enabled': isFirebaseConfigured,
        'analytics_enabled': enableAnalytics,
        'debug_mode': debugMode,
      };
}

/// Helper class for API error messages
class ApiErrorMessages {
  static const String noApiKey =
      'API key not configured. Please provide a valid API key.';

  static const String networkError =
      'Network error. Please check your internet connection.';

  static const String timeout =
      'Request timed out. Please try again.';

  static const String rateLimited =
      'Too many requests. Please wait a moment and try again.';

  static const String serverError =
      'Server error. Please try again later.';

  static const String invalidImage =
      'Invalid image format. Please use a clear photo.';

  static const String imageTooLarge =
      'Image too large. Please use a smaller image.';

  static const String insufficientCredits =
      'Insufficient API credits. Please check your account.';

  static String getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Invalid API key. Please check your configuration.';
      case 403:
        return 'Access forbidden. Please check your API permissions.';
      case 429:
        return rateLimited;
      case 500:
      case 502:
      case 503:
        return serverError;
      default:
        return 'An error occurred (Code: $statusCode). Please try again.';
    }
  }
}
