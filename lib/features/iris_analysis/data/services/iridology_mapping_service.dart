// lib/features/iris_analysis/data/services/iridology_mapping_service.dart
// Main service orchestrating iridology analysis

import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../../../core/constants/iridology_zones.dart';
import '../../domain/entities/iridology_analysis.dart';
import 'iris_segmentation_service.dart';
import 'color_analysis_service.dart';

/// Main service for performing iridology analysis
class IridologyMappingService {
  final IrisSegmentationService _segmentationService = IrisSegmentationService();
  final ColorAnalysisService _colorAnalysisService = ColorAnalysisService();
  final _uuid = const Uuid();

  /// Perform complete iridology analysis on an iris image
  Future<IridologyAnalysis> analyzeIris({
    required Uint8List irisImageBytes,
    required bool isLeftEye,
  }) async {
    // Decode image
    final irisImage = img.decodeImage(irisImageBytes);
    if (irisImage == null) {
      throw Exception('Failed to decode iris image');
    }

    // Get zones for this eye
    final zones = IridologyZones.getZonesForEye(isLeftEye);

    // Analyze overall color profile
    final overallColorProfile = await _colorAnalysisService.analyzeOverallColor(irisImage);

    // Analyze each zone
    final zoneAnalyses = <ZoneAnalysis>[];
    for (final zone in zones) {
      final zoneAnalysis = await _analyzeZone(
        irisImage: irisImage,
        zone: zone,
        overallColorProfile: overallColorProfile,
      );
      zoneAnalyses.add(zoneAnalysis);
    }

    // Generate wellness insights
    final insights = _generateInsights(zoneAnalyses, isLeftEye);

    // Calculate analysis confidence
    final confidence = _calculateConfidence(zoneAnalyses);

    return IridologyAnalysis(
      id: _uuid.v4(),
      isLeftEye: isLeftEye,
      zoneAnalyses: zoneAnalyses,
      insights: insights,
      timestamp: DateTime.now(),
      overallColorProfile: overallColorProfile,
      analysisConfidence: confidence,
    );
  }

  /// Analyze a specific zone
  Future<ZoneAnalysis> _analyzeZone({
    required img.Image irisImage,
    required IridologyZone zone,
    required IrisColorProfile overallColorProfile,
  }) async {
    // Extract pixels for this zone
    final pixels = await _segmentationService.extractZonePixels(
      irisImage: irisImage,
      zone: zone,
    );

    if (pixels.isEmpty) {
      return ZoneAnalysis(
        zone: zone,
        colorProfile: const ColorProfile(
          red: 0,
          green: 0,
          blue: 0,
          brightness: 0,
          saturation: 0,
          dominantColor: IrisColorType.mixed,
        ),
        textureFeatures: const TextureFeatures(
          uniformity: 0,
          density: 0,
          patterns: [],
          patternStrength: 0,
        ),
        observations: ['Insufficient data for this zone'],
        significanceScore: 0.0,
      );
    }

    // Analyze color profile
    final colorProfile = await _colorAnalysisService.analyzePixels(pixels);

    // Simple texture analysis (uniformity and density)
    final textureFeatures = _analyzeTexture(pixels);

    // Generate observations
    final observations = _generateObservations(
      zone: zone,
      colorProfile: colorProfile,
      overallColor: overallColorProfile,
    );

    // Calculate significance score
    final significance = _calculateZoneSignificance(
      colorProfile: colorProfile,
      textureFeatures: textureFeatures,
      observations: observations,
    );

    return ZoneAnalysis(
      zone: zone,
      colorProfile: colorProfile,
      textureFeatures: textureFeatures,
      observations: observations,
      significanceScore: significance,
    );
  }

  /// Simple texture analysis
  TextureFeatures _analyzeTexture(List<img.Pixel> pixels) {
    if (pixels.length < 10) {
      return const TextureFeatures(
        uniformity: 0,
        density: 0,
        patterns: [],
        patternStrength: 0,
      );
    }

    // Calculate color uniformity (low std dev = high uniformity)
    double totalR = 0, totalG = 0, totalB = 0;
    for (final pixel in pixels) {
      totalR += pixel.r;
      totalG += pixel.g;
      totalB += pixel.b;
    }

    final avgR = totalR / pixels.length;
    final avgG = totalG / pixels.length;
    final avgB = totalB / pixels.length;

    double variance = 0;
    for (final pixel in pixels) {
      final diffR = pixel.r - avgR;
      final diffG = pixel.g - avgG;
      final diffB = pixel.b - avgB;
      variance += (diffR * diffR + diffG * diffG + diffB * diffB);
    }
    variance /= pixels.length;

    final uniformity = (1.0 - (variance / 65025)).clamp(0.0, 1.0); // 65025 = 255^2

    // Estimate density (average brightness)
    final density = (avgR + avgG + avgB) / (3 * 255);

    return TextureFeatures(
      uniformity: uniformity,
      density: density,
      patterns: [PatternType.uniform],
      patternStrength: uniformity,
    );
  }

  /// Generate observations for a zone
  List<String> _generateObservations({
    required IridologyZone zone,
    required ColorProfile colorProfile,
    required IrisColorProfile overallColor,
  }) {
    final observations = <String>[];

    // Check brightness
    if (colorProfile.brightness < 0.3) {
      observations.add('Darker pigmentation in ${zone.name} zone');
    } else if (colorProfile.brightness > 0.7) {
      observations.add('Lighter coloration in ${zone.name} zone');
    }

    // Check saturation
    if (colorProfile.saturation > 0.6) {
      observations.add('Notable color intensity in ${zone.name}');
    }

    // Check if color differs from overall
    if (colorProfile.dominantColor != overallColor.primaryColor) {
      observations.add('Color variation in ${zone.name} area');
    }

    if (observations.isEmpty) {
      observations.add('${zone.name} shows typical characteristics');
    }

    return observations;
  }

  /// Calculate zone significance score
  double _calculateZoneSignificance({
    required ColorProfile colorProfile,
    required TextureFeatures textureFeatures,
    required List<String> observations,
  }) {
    double score = 0.0;

    // Brightness extremes increase significance
    if (colorProfile.brightness < 0.3 || colorProfile.brightness > 0.7) {
      score += 0.3;
    }

    // High saturation increases significance
    if (colorProfile.saturation > 0.5) {
      score += 0.2;
    }

    // Low uniformity increases significance
    if (textureFeatures.uniformity < 0.6) {
      score += 0.2;
    }

    // Multiple observations increase significance
    score += observations.length * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Generate wellness insights from zone analyses
  List<WellnessInsight> _generateInsights(
    List<ZoneAnalysis> zoneAnalyses,
    bool isLeftEye,
  ) {
    final insights = <WellnessInsight>[];

    // Group zones by body system
    final systemZones = <String, List<ZoneAnalysis>>{};
    for (final analysis in zoneAnalyses) {
      final system = analysis.zone.bodySystem;
      systemZones[system] = [...(systemZones[system] ?? []), analysis];
    }

    // Generate insights for each body system
    for (final entry in systemZones.entries) {
      final system = entry.key;
      final zones = entry.value;

      // Get notable zones
      final notableZones = zones.where((z) => z.isNotable).toList();

      if (notableZones.isNotEmpty) {
        final zone = notableZones.first.zone;

        insights.add(WellnessInsight(
          id: _uuid.v4(),
          bodySystem: system,
          title: zone.name,
          description: zone.description,
          reflectionPrompts: zone.wellnessReflections,
          category: _getCategoryForSystem(system),
          confidence: notableZones.first.significanceScore,
          relatedZones: notableZones.map((z) => z.zone.id).toList(),
        ));
      } else {
        // General insight for system
        final zone = zones.first.zone;
        insights.add(WellnessInsight(
          id: _uuid.v4(),
          bodySystem: system,
          title: '$system System',
          description: 'General wellness reflection for $system',
          reflectionPrompts: zone.wellnessReflections.take(2).toList(),
          category: _getCategoryForSystem(system),
          confidence: 0.5,
          relatedZones: zones.map((z) => z.zone.id).toList(),
        ));
      }
    }

    return insights;
  }

  /// Get insight category for body system
  InsightCategory _getCategoryForSystem(String system) {
    switch (system) {
      case 'Digestive':
        return InsightCategory.nutrition;
      case 'Respiratory':
      case 'Cardiovascular':
        return InsightCategory.activity;
      case 'Nervous':
        return InsightCategory.stress;
      case 'Urinary':
      case 'Immune':
      case 'Endocrine':
        return InsightCategory.lifestyle;
      default:
        return InsightCategory.general;
    }
  }

  /// Calculate overall analysis confidence
  double _calculateConfidence(List<ZoneAnalysis> zoneAnalyses) {
    if (zoneAnalyses.isEmpty) return 0.0;

    final avgSignificance = zoneAnalyses
            .map((z) => z.significanceScore)
            .reduce((a, b) => a + b) /
        zoneAnalyses.length;

    return (avgSignificance * 0.7 + 0.3).clamp(0.0, 1.0);
  }
}
