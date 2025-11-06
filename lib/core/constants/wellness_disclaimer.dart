// lib/core/constants/wellness_disclaimer.dart
// Legal disclaimer texts for GDPR/MHRA compliance

/// Contains all legal disclaimers required for wellness app compliance
/// CRITICAL: These disclaimers protect users and the app from medical liability
class WellnessDisclaimer {
  /// Short disclaimer for banners and quick reference
  static const String shortDisclaimer =
      'For wellness education only. Not medical advice.';

  /// Comprehensive legal disclaimer
  static const String fullDisclaimer = '''
IMPORTANT HEALTH INFORMATION DISCLAIMER

This application is designed for wellness education and artistic expression purposes only.

NOT A MEDICAL DEVICE: This app is not a medical device and has not been evaluated or approved by any regulatory health authority (FDA, MHRA, TGA, or equivalent).

NOT FOR DIAGNOSIS: The insights and information provided are NOT medical diagnoses and should NOT be used to diagnose, treat, cure, or prevent any disease or medical condition.

EDUCATIONAL PURPOSE: Iridology is considered a complementary wellness practice and is not validated by conventional medicine. The associations between iris patterns and body systems are based on traditional iridology theory, not scientific medical evidence.

CONSULT PROFESSIONALS: Always consult qualified healthcare professionals for any medical concerns, symptoms, or before making any changes to your health routine, diet, or lifestyle.

NO GUARANTEES: We make no claims, guarantees, or warranties about the accuracy, completeness, or reliability of any wellness insights provided by this application.

PRIVACY: While we prioritize your privacy with on-device processing options, please review our Privacy Policy to understand how your data is processed.

ARTISTIC EXPRESSION: The AI art generation features are for creative and artistic purposes. Generated images should be enjoyed as digital art, not analyzed for medical purposes.

By using this app, you acknowledge and accept that:
• You are using it for informational and creative purposes only
• You will not rely on it for medical decisions
• You understand the limitations of iridology as a practice
• You will seek professional medical advice when needed

EMERGENCY: If you experience any medical emergency, symptoms, or health concerns, please contact your healthcare provider or emergency services immediately.

Last Updated: November 2025
''';

  /// First-time user agreement (shorter, user-friendly)
  static const String firstTimeUserAgreement = '''
Welcome to Iris Art & Wellness!

Before you begin, please read and accept:

✓ This app is for wellness exploration and creative expression
✓ It is NOT a medical diagnostic tool
✓ Insights are educational, not medical advice
✓ Always consult healthcare professionals for medical concerns

This app combines traditional iridology principles with AI art generation to create a unique wellness and creativity experience.

Do you understand and agree to these terms?
''';

  /// Onboarding disclaimer (engaging, educational tone)
  static const String onboardingDisclaimer = '''
🌟 Explore Your Unique Iris

This app combines:
• Gentle wellness reflections inspired by iridology
• Beautiful AI-generated iris art
• Personal journaling and tracking

Remember: This is about curiosity and self-expression, not medical diagnosis. Think of it as a wellness journal meets digital art studio!
''';

  /// Banner text for wellness insight screens
  static const String insightsBanner =
      'Educational wellness reflections • Not medical advice • Consult healthcare professionals for medical concerns';

  /// Quick reminder for sharing features
  static const String sharingReminder =
      'Wellness insights are for personal reflection only. Always respect privacy and seek professional advice for health concerns.';

  /// Terms of Service summary
  static const String tosHighlights = '''
Key Terms of Use:

1. AGE REQUIREMENT
   • You must be 18+ or have parental consent

2. INTENDED USE
   • Wellness education and artistic expression
   • Not for medical diagnosis or treatment

3. DATA & PRIVACY
   • Your iris images are processed securely
   • You control what data is stored
   • See Privacy Policy for full details

4. SUBSCRIPTIONS
   • Pro features require subscription
   • Cancel anytime through your app store
   • No refunds for partial periods

5. INTELLECTUAL PROPERTY
   • You own your iris images
   • Generated art may be used in your marketing
   • Don't use images of others without consent

6. LIMITATION OF LIABILITY
   • Use at your own risk
   • No medical guarantees or claims
   • Not liable for health decisions

Full Terms: [link to full TOS]
Privacy Policy: [link to privacy policy]
''';

  /// Privacy highlights
  static const String privacyHighlights = '''
Your Privacy Matters:

🔒 ON-DEVICE FIRST
   • Iris detection runs on your device
   • No images sent to servers by default

🎨 OPTIONAL CLOUD
   • AI art generation uses cloud API
   • Only processed images are sent
   • Original photos stay on your device

💾 YOUR CONTROL
   • Choose what to save locally
   • Delete your data anytime (GDPR right)
   • Export your data on request

📊 ANALYTICS
   • Anonymous usage statistics only
   • No personal health data collected
   • Opt-out available in settings

🔐 SECURITY
   • Encrypted local storage
   • No selling of data to third parties
   • Compliance with GDPR, CCPA

Read full Privacy Policy: [link]
''';

  /// GDPR compliance text
  static const String gdprRights = '''
Your Data Rights (GDPR):

Under GDPR, you have the right to:

1. ACCESS - See what data we have about you
2. RECTIFICATION - Correct inaccurate data
3. ERASURE - Delete your data ("right to be forgotten")
4. PORTABILITY - Export your data
5. RESTRICTION - Limit how we process your data
6. OBJECTION - Object to certain data processing
7. WITHDRAW CONSENT - Change your mind anytime

To exercise these rights:
• Use in-app data management tools
• Contact: privacy@irisapp.com
• Response within 30 days

Data Controller: [Company Name]
DPO Contact: [DPO Email]
''';

  /// Health disclaimer widget text
  static const String widgetDisclaimer =
      '⚠️ Not medical advice. For educational wellness exploration only.';

  /// App Store description disclaimer
  static const String appStoreDisclaimer = '''
HEALTH DISCLAIMER: This app is for wellness education and artistic expression only. It is NOT a medical device and should NOT be used for medical diagnosis or treatment. Iridology is not validated by conventional medicine. Always consult qualified healthcare professionals for medical concerns.
''';
}

/// Helper class for showing disclaimers in UI
class DisclaimerHelper {
  /// Check if user has accepted terms (for first-time use)
  static const String sharedPrefsKey = 'has_accepted_disclaimer';

  /// Recommended frequency for showing disclaimer reminders
  static const Duration reminderInterval = Duration(days: 30);

  /// Color codes for disclaimer UI
  static const disclaimerBackgroundColor = 0xFFFFF3E0; // Amber 50
  static const disclaimerTextColor = 0xFFE65100; // Amber 900
  static const disclaimerIconColor = 0xFFFF6F00; // Amber 700
}
