// lib/features/onboarding/presentation/screens/onboarding_screen.dart
// Onboarding flow with legal disclaimers and feature introduction

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/wellness_disclaimer.dart';
import '../../../camera/presentation/screens/iris_camera_screen_v2.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasAcceptedTerms = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Iris',
      description: 'Transform your iris into stunning digital art while '
          'exploring wellness insights based on traditional iridology',
      icon: Icons.visibility,
      color: Color(0xFF6366F1),
    ),
    OnboardingPage(
      title: 'Capture Your Iris',
      description: 'Our guided camera makes it easy to capture a clear '
          'photo of your eye with real-time quality checks',
      icon: Icons.camera_alt,
      color: Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      title: 'Wellness Reflections',
      description: 'Receive gentle wellness insights based on traditional '
          'iridology principles - for educational purposes only',
      icon: Icons.spa,
      color: Color(0xFF10B981),
    ),
    OnboardingPage(
      title: 'Create Beautiful Art',
      description: 'Turn your iris into unique artwork with AI-powered '
          'style transformations. Choose from multiple artistic styles!',
      icon: Icons.palette,
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Skip'),
                ),
              ),

            // Page view
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
                child: Column(
                  children: [
                    // Disclaimer card
                    Card(
                      color: const Color(0xFFFFF3E0), // Amber 50
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFE65100), // Amber 900
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Important Health Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              WellnessDisclaimer.firstTimeUserAgreement,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6D4C41), // Brown 700
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _showFullDisclaimer,
                              child: const Text('Read Full Disclaimer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Acceptance checkbox
                    CheckboxListTile(
                      value: _hasAcceptedTerms,
                      onChanged: (value) {
                        setState(() => _hasAcceptedTerms = value ?? false);
                      },
                      title: const Text(
                        'I understand this app is for wellness education '
                        'and creative expression, not medical diagnosis',
                        style: TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
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
          // Icon
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFullDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Health Disclaimer'),
        content: SingleChildScrollView(
          child: Text(
            WellnessDisclaimer.fullDisclaimer,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Save that user has completed onboarding and accepted disclaimer
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('has_accepted_disclaimer', true);
    await prefs.setString(
      'disclaimer_accepted_date',
      DateTime.now().toIso8601String(),
    );

    // Navigate to camera screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const IrisCameraScreenV2(),
        ),
      );
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
