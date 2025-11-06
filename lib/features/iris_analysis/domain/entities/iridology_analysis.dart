// lib/features/iris_analysis/domain/entities/iridology_analysis.dart
// Domain entities for iridology analysis results

import '../../../../core/constants/iridology_zones.dart';

/// Represents a complete iridology analysis of an iris
class IridologyAnalysis {
  final String id;
  final bool isLeftEye;
  final List<ZoneAnalysis> zoneAnalyses;
  final List<WellnessInsight> insights;
  final DateTime timestamp;
  final IrisColorProfile overallColorProfile;
  final double analysisConfidence;

  const IridologyAnalysis({
    required this.id,
    required this.isLeftEye,
    required this.zoneAnalyses,
    required this.insights,
    required this.timestamp,
    required this.overallColorProfile,
    required this.analysisConfidence,
  });

  /// Get insights for a specific body system
  List<WellnessInsight> getInsightsForSystem(String bodySystem) {
    return insights.where((i) => i.bodySystem == bodySystem).toList();
  }

  /// Get zone analysis by zone ID
  ZoneAnalysis? getZoneAnalysis(String zoneId) {
    try {
      return zoneAnalyses.firstWhere((z) => z.zone.id == zoneId);
    } catch (e) {
      return null;
    }
  }

  /// Get all unique body systems in this analysis
  List<String> get bodySystems {
    final systems = <String>{};
    for (final insight in insights) {
      systems.add(insight.bodySystem);
    }
    return systems.toList()..sort();
  }

  /// Get summary of analysis
  String get summary {
    return '${insights.length} wellness insights across ${bodySystems.length} body systems';
  }
}

/// Analysis of a specific iris zone
class ZoneAnalysis {
  final IridologyZone zone;
  final ColorProfile colorProfile;
  final TextureFeatures textureFeatures;
  final List<String> observations;
  final double significanceScore; // 0.0 to 1.0

  const ZoneAnalysis({
    required this.zone,
    required this.colorProfile,
    required this.textureFeatures,
    required this.observations,
    required this.significanceScore,
  });

  /// Check if this zone shows notable characteristics
  bool get isNotable => significanceScore > 0.6;

  /// Get primary observation
  String? get primaryObservation =>
      observations.isNotEmpty ? observations.first : null;
}

/// Color profile of an iris region
class ColorProfile {
  final double red; // 0.0 to 1.0
  final double green;
  final double blue;
  final double brightness;
  final double saturation;
  final IrisColorType dominantColor;
  final List<IrisColorType> secondaryColors;

  const ColorProfile({
    required this.red,
    required this.green,
    required this.blue,
    required this.brightness,
    required this.saturation,
    required this.dominantColor,
    this.secondaryColors = const [],
  });

  /// Get HSV hue (0-360 degrees)
  double get hue {
    final maxC = [red, green, blue].reduce((a, b) => a > b ? a : b);
    final minC = [red, green, blue].reduce((a, b) => a < b ? a : b);
    final delta = maxC - minC;

    if (delta == 0) return 0;

    double hue;
    if (maxC == red) {
      hue = 60 * (((green - blue) / delta) % 6);
    } else if (maxC == green) {
      hue = 60 * (((blue - red) / delta) + 2);
    } else {
      hue = 60 * (((red - green) / delta) + 4);
    }

    return hue < 0 ? hue + 360 : hue;
  }

  /// Get color description
  String get colorDescription {
    switch (dominantColor) {
      case IrisColorType.blue:
        return 'Blue tones';
      case IrisColorType.green:
        return 'Green tones';
      case IrisColorType.brown:
        return 'Brown tones';
      case IrisColorType.hazel:
        return 'Hazel tones';
      case IrisColorType.gray:
        return 'Gray tones';
      case IrisColorType.amber:
        return 'Amber tones';
      case IrisColorType.mixed:
        return 'Mixed tones';
    }
  }
}

/// Overall iris color profile
class IrisColorProfile {
  final IrisColorType primaryColor;
  final List<IrisColorType> secondaryColors;
  final double colorVariation; // 0.0 to 1.0
  final bool hasDistinctZones;

  const IrisColorProfile({
    required this.primaryColor,
    required this.secondaryColors,
    required this.colorVariation,
    required this.hasDistinctZones,
  });

  String get description {
    final primary = primaryColor.displayName;
    if (secondaryColors.isEmpty) {
      return 'Predominantly $primary';
    } else {
      final secondary = secondaryColors.map((c) => c.displayName).join(', ');
      return '$primary with $secondary accents';
    }
  }
}

/// Texture and pattern features
class TextureFeatures {
  final double uniformity; // 0.0 to 1.0
  final double density; // 0.0 to 1.0
  final List<PatternType> patterns;
  final double patternStrength; // 0.0 to 1.0

  const TextureFeatures({
    required this.uniformity,
    required this.density,
    required this.patterns,
    required this.patternStrength,
  });

  /// Check if texture is uniform
  bool get isUniform => uniformity > 0.7;

  /// Get primary pattern
  PatternType? get primaryPattern =>
      patterns.isNotEmpty ? patterns.first : null;
}

/// Types of iris patterns
enum PatternType {
  radial('Radial fibers'),
  circular('Circular rings'),
  crypts('Crypts'),
  furrows('Furrows'),
  spots('Pigmentation spots'),
  uniform('Uniform texture');

  final String displayName;
  const PatternType(this.displayName);
}

/// Iris color classification
enum IrisColorType {
  blue('Blue'),
  green('Green'),
  brown('Brown'),
  hazel('Hazel'),
  gray('Gray'),
  amber('Amber'),
  mixed('Mixed');

  final String displayName;
  const IrisColorType(this.displayName);
}

/// Wellness insight generated from iris analysis
class WellnessInsight {
  final String id;
  final String bodySystem;
  final String title;
  final String description;
  final List<String> reflectionPrompts;
  final InsightCategory category;
  final double confidence; // 0.0 to 1.0
  final List<String> relatedZones;

  const WellnessInsight({
    required this.id,
    required this.bodySystem,
    required this.title,
    required this.description,
    required this.reflectionPrompts,
    required this.category,
    required this.confidence,
    this.relatedZones = const [],
  });

  /// Check if this is a high confidence insight
  bool get isHighConfidence => confidence > 0.7;

  /// Get confidence level description
  String get confidenceLevel {
    if (confidence > 0.8) return 'Strong';
    if (confidence > 0.6) return 'Moderate';
    return 'Subtle';
  }
}

/// Categories of wellness insights
enum InsightCategory {
  general('General Wellness'),
  lifestyle('Lifestyle'),
  nutrition('Nutrition'),
  stress('Stress & Rest'),
  activity('Physical Activity'),
  environmental('Environment');

  final String displayName;
  const InsightCategory(this.displayName);
}

/// Wellness recommendation
class WellnessRecommendation {
  final String title;
  final String description;
  final RecommendationType type;
  final List<String> actionItems;

  const WellnessRecommendation({
    required this.title,
    required this.description,
    required this.type,
    required this.actionItems,
  });
}

/// Types of wellness recommendations
enum RecommendationType {
  lifestyle,
  nutrition,
  exercise,
  rest,
  environment,
  mindfulness,
}
