// lib/features/art_generation/presentation/screens/art_style_selector_screen.dart
// Screen for selecting art style for iris transformation

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/art_styles.dart';
import '../../domain/entities/art_generation_result.dart';
import '../../data/services/stability_ai_service.dart';
import 'art_result_screen.dart';

/// Screen for selecting an art style
class ArtStyleSelectorScreen extends StatefulWidget {
  final Uint8List irisImage;
  final bool isPro;

  const ArtStyleSelectorScreen({
    super.key,
    required this.irisImage,
    this.isPro = false,
  });

  @override
  State<ArtStyleSelectorScreen> createState() => _ArtStyleSelectorScreenState();
}

class _ArtStyleSelectorScreenState extends State<ArtStyleSelectorScreen> {
  final _uuid = const Uuid();
  ArtStyle? _selectedStyle;

  @override
  Widget build(BuildContext context) {
    final freeStyles = ArtStyles.allStyles.where((s) => !s.isPro).toList();
    final proStyles = ArtStyles.allStyles.where((s) => s.isPro).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Art Style'),
        actions: [
          if (!widget.isPro)
            TextButton.icon(
              onPressed: _showProUpgradeDialog,
              icon: const Icon(Icons.star, color: Colors.amber),
              label: const Text('Go Pro'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select an art style to transform your iris into beautiful artwork',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Free styles section
            const Text(
              'Free Styles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${freeStyles.length} styles available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: freeStyles.length,
              itemBuilder: (context, index) {
                return _StyleCard(
                  style: freeStyles[index],
                  isSelected: _selectedStyle?.id == freeStyles[index].id,
                  isLocked: false,
                  onTap: () => _selectStyle(freeStyles[index]),
                );
              },
            ),

            const SizedBox(height: 32),

            // Pro styles section
            Row(
              children: [
                const Text(
                  'Pro Styles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${proStyles.length} premium styles',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: proStyles.length,
              itemBuilder: (context, index) {
                return _StyleCard(
                  style: proStyles[index],
                  isSelected: _selectedStyle?.id == proStyles[index].id,
                  isLocked: !widget.isPro,
                  onTap: () => widget.isPro
                      ? _selectStyle(proStyles[index])
                      : _showProUpgradeDialog(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedStyle != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _generateArt,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Art'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _selectStyle(ArtStyle style) {
    setState(() {
      _selectedStyle = style;
    });
  }

  Future<void> _generateArt() async {
    if (_selectedStyle == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _GeneratingDialog(),
    );

    try {
      // Create art generation request
      final request = widget.isPro
          ? ArtGenerationRequest.proQuality(
              id: _uuid.v4(),
              irisImage: widget.irisImage,
              style: _selectedStyle!,
            )
          : ArtGenerationRequest.freeQuality(
              id: _uuid.v4(),
              irisImage: widget.irisImage,
              style: _selectedStyle!,
            );

      // For demo purposes, use mock generation
      // In production, check if API key is configured
      final config = ArtGenerationConfig(
        apiKey: '', // Will be loaded from environment/config
      );
      final service = StabilityAIService(config: config);

      // Use mock generation for now (no API key required)
      final result = await service.generateArtMock(request: request);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (result.isSuccess) {
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtResultScreen(result: result),
          ),
        );
      } else {
        // Show error
        _showError(result.errorMessage ?? 'Generation failed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError('Unexpected error: $e');
    }
  }

  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade to Pro'),
          ],
        ),
        content: const Text(
          'Unlock all 12 premium art styles, 4K exports, and unlimited generations with Iris Pro!\n\n'
          '• 8 exclusive pro styles\n'
          '• 4K high-resolution exports\n'
          '• No watermarks\n'
          '• Unlimited scan history\n'
          '• Priority support',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to subscription screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription screen coming soon!'),
                ),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final ArtStyle style;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview image placeholder
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _getColorForStyle(style),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getColorForStyle(style),
                          _getColorForStyle(style).withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconForStyle(style),
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  if (isLocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (isSelected && !isLocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Style info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          style.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (style.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForStyle(ArtStyle style) {
    switch (style.id) {
      case 'neon_cyber':
        return Colors.purple;
      case 'watercolor_dream':
        return Colors.blue;
      case 'oil_painting':
        return Colors.brown;
      case 'minimalist':
        return Colors.grey;
      case 'cosmic_galaxy':
        return Colors.deepPurple;
      case 'geometric_gold':
        return Colors.amber;
      case 'botanical_life':
        return Colors.green;
      case 'stained_glass':
        return Colors.red;
      case 'abstract_emotion':
        return Colors.orange;
      case 'mandala_zen':
        return Colors.teal;
      case 'impressionist':
        return Colors.lightBlue;
      case 'surreal_dream':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForStyle(ArtStyle style) {
    switch (style.id) {
      case 'neon_cyber':
        return Icons.electric_bolt;
      case 'watercolor_dream':
        return Icons.water_drop;
      case 'oil_painting':
        return Icons.brush;
      case 'minimalist':
        return Icons.minimize;
      case 'cosmic_galaxy':
        return Icons.star;
      case 'geometric_gold':
        return Icons.hexagon;
      case 'botanical_life':
        return Icons.local_florist;
      case 'stained_glass':
        return Icons.window;
      case 'abstract_emotion':
        return Icons.palette;
      case 'mandala_zen':
        return Icons.spa;
      case 'impressionist':
        return Icons.landscape;
      case 'surreal_dream':
        return Icons.cloud;
      default:
        return Icons.image;
    }
  }
}

class _GeneratingDialog extends StatelessWidget {
  const _GeneratingDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Generating your art...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take up to 30 seconds',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
