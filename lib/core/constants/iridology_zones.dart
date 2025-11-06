// lib/core/constants/iridology_zones.dart
// Comprehensive iridology zone definitions based on traditional iridology charts

import 'dart:math';

/// Represents a specific zone in the iris mapped to body systems
/// Based on traditional iridology principles (Bernard Jensen charts)
class IridologyZone {
  final String id;
  final String name;
  final String bodySystem;
  final double startAngle; // In radians (0 = 3 o'clock position)
  final double endAngle;
  final double innerRadius; // Normalized 0.0 to 1.0 (0 = center, 1 = edge)
  final double outerRadius;
  final String description;
  final List<String> wellnessReflections;

  const IridologyZone({
    required this.id,
    required this.name,
    required this.bodySystem,
    required this.startAngle,
    required this.endAngle,
    required this.innerRadius,
    required this.outerRadius,
    required this.description,
    required this.wellnessReflections,
  });

  /// Check if a point (angle, radius) falls within this zone
  bool containsPoint(double angle, double radius) {
    // Normalize angle to 0-2π
    final normalizedAngle = angle % (2 * pi);

    // Check if point is within this zone
    final angleInRange =
        normalizedAngle >= startAngle && normalizedAngle <= endAngle;
    final radiusInRange = radius >= innerRadius && radius <= outerRadius;

    return angleInRange && radiusInRange;
  }

  /// Get icon for this body system
  String get iconName {
    switch (bodySystem) {
      case 'Digestive':
        return 'restaurant';
      case 'Respiratory':
        return 'air';
      case 'Cardiovascular':
        return 'favorite';
      case 'Nervous':
        return 'psychology';
      case 'Urinary':
        return 'water_drop';
      case 'Immune':
        return 'shield';
      default:
        return 'health_and_safety';
    }
  }
}

/// Collection of iridology zones for both eyes
class IridologyZones {
  // Helper function to convert clock position to radians
  // 12 o'clock = π/2 (90°), going clockwise
  static double clockToRadians(int hour) {
    return (pi / 2) - (hour * pi / 6);
  }

  /// RIGHT EYE ZONES
  /// Based on standard iridology charts by Bernard Jensen
  static final List<IridologyZone> rightEyeZones = [
    // PUPILLARY ZONE (Digestive System - center)
    IridologyZone(
      id: 're_stomach',
      name: 'Stomach',
      bodySystem: 'Digestive',
      startAngle: 0,
      endAngle: 2 * pi,
      innerRadius: 0.0,
      outerRadius: 0.3,
      description: 'Central digestive area',
      wellnessReflections: [
        'How is your digestion after meals?',
        'Consider meal timing and portion sizes',
        'Reflect on your hydration habits',
        'Are you chewing your food thoroughly?',
      ],
    ),

    // LIVER ZONE (5-7 o'clock right eye)
    IridologyZone(
      id: 're_liver',
      name: 'Liver',
      bodySystem: 'Digestive',
      startAngle: clockToRadians(7),
      endAngle: clockToRadians(5),
      innerRadius: 0.3,
      outerRadius: 0.6,
      description: 'Liver and detoxification zone',
      wellnessReflections: [
        'How are your energy levels throughout the day?',
        'Consider your body\'s natural detox processes',
        'Reflect on sleep quality and rest',
        'Are you supporting your liver with nutrition?',
      ],
    ),

    // GALLBLADDER (5-6 o'clock)
    IridologyZone(
      id: 're_gallbladder',
      name: 'Gallbladder',
      bodySystem: 'Digestive',
      startAngle: clockToRadians(6),
      endAngle: clockToRadians(5),
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Gallbladder zone',
      wellnessReflections: [
        'How do you feel after fatty meals?',
        'Consider balanced nutrition',
        'Reflect on dietary fat sources',
      ],
    ),

    // RIGHT LUNG (2-3 o'clock)
    IridologyZone(
      id: 're_lung',
      name: 'Right Lung',
      bodySystem: 'Respiratory',
      startAngle: clockToRadians(3),
      endAngle: clockToRadians(2),
      innerRadius: 0.4,
      outerRadius: 0.7,
      description: 'Right respiratory zone',
      wellnessReflections: [
        'Are you practicing deep breathing?',
        'Consider air quality in your environment',
        'Reflect on your breathing patterns',
        'Do you get adequate fresh air daily?',
      ],
    ),

    // RIGHT KIDNEY (7-8 o'clock)
    IridologyZone(
      id: 're_kidney',
      name: 'Right Kidney',
      bodySystem: 'Urinary',
      startAngle: clockToRadians(8),
      endAngle: clockToRadians(7),
      innerRadius: 0.5,
      outerRadius: 0.7,
      description: 'Right kidney and adrenal zone',
      wellnessReflections: [
        'How is your hydration?',
        'Consider your stress levels',
        'Reflect on your body\'s rest needs',
        'Are you drinking enough water daily?',
      ],
    ),

    // BRAIN (11-1 o'clock)
    IridologyZone(
      id: 're_brain',
      name: 'Right Brain Hemisphere',
      bodySystem: 'Nervous',
      startAngle: clockToRadians(1),
      endAngle: clockToRadians(11),
      innerRadius: 0.6,
      outerRadius: 0.8,
      description: 'Right brain and nervous system',
      wellnessReflections: [
        'How are your stress levels?',
        'Consider mental clarity and focus',
        'Reflect on your sleep quality',
        'Are you taking breaks for mental rest?',
      ],
    ),

    // HEART (3-4 o'clock right eye)
    IridologyZone(
      id: 're_heart',
      name: 'Heart',
      bodySystem: 'Cardiovascular',
      startAngle: clockToRadians(4),
      endAngle: clockToRadians(3),
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Cardiovascular zone',
      wellnessReflections: [
        'How is your cardiovascular activity?',
        'Consider movement and exercise',
        'Reflect on emotional wellness',
        'Are you moving your body regularly?',
      ],
    ),

    // LYMPHATIC RING (outer edge)
    IridologyZone(
      id: 're_lymphatic',
      name: 'Lymphatic System',
      bodySystem: 'Immune',
      startAngle: 0,
      endAngle: 2 * pi,
      innerRadius: 0.8,
      outerRadius: 1.0,
      description: 'Lymphatic and immune zone',
      wellnessReflections: [
        'How is your overall vitality?',
        'Consider immune system support',
        'Reflect on rest and recovery',
        'Are you managing stress effectively?',
      ],
    ),

    // Additional zones for comprehensive mapping
    // INTESTINES (4-8 o'clock)
    IridologyZone(
      id: 're_intestines',
      name: 'Intestines',
      bodySystem: 'Digestive',
      startAngle: clockToRadians(8),
      endAngle: clockToRadians(4),
      innerRadius: 0.3,
      outerRadius: 0.5,
      description: 'Intestinal zone',
      wellnessReflections: [
        'How is your digestive regularity?',
        'Consider fiber and water intake',
        'Reflect on gut-friendly foods',
      ],
    ),

    // THYROID (9-10 o'clock)
    IridologyZone(
      id: 're_thyroid',
      name: 'Thyroid',
      bodySystem: 'Endocrine',
      startAngle: clockToRadians(10),
      endAngle: clockToRadians(9),
      innerRadius: 0.5,
      outerRadius: 0.7,
      description: 'Thyroid and metabolic zone',
      wellnessReflections: [
        'How are your energy levels?',
        'Consider metabolic health',
        'Reflect on temperature regulation',
      ],
    ),
  ];

  /// LEFT EYE ZONES
  /// Mirror of right eye with left-side organ correspondences
  static final List<IridologyZone> leftEyeZones = [
    // Central stomach zone (same as right)
    IridologyZone(
      id: 'le_stomach',
      name: 'Stomach',
      bodySystem: 'Digestive',
      startAngle: 0,
      endAngle: 2 * pi,
      innerRadius: 0.0,
      outerRadius: 0.3,
      description: 'Central digestive area',
      wellnessReflections: [
        'How is your digestion after meals?',
        'Consider meal timing and portion sizes',
        'Reflect on your hydration habits',
      ],
    ),

    // HEART (8-9 o'clock left eye - mirrored position)
    IridologyZone(
      id: 'le_heart',
      name: 'Heart',
      bodySystem: 'Cardiovascular',
      startAngle: clockToRadians(9),
      endAngle: clockToRadians(8),
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Heart zone (left eye)',
      wellnessReflections: [
        'How is your cardiovascular wellness?',
        'Consider emotional balance',
        'Reflect on stress management',
        'Are you nurturing your heart health?',
      ],
    ),

    // LEFT LUNG (9-10 o'clock)
    IridologyZone(
      id: 'le_lung',
      name: 'Left Lung',
      bodySystem: 'Respiratory',
      startAngle: clockToRadians(10),
      endAngle: clockToRadians(9),
      innerRadius: 0.4,
      outerRadius: 0.7,
      description: 'Left respiratory zone',
      wellnessReflections: [
        'Are you practicing deep breathing?',
        'Consider air quality in your environment',
        'Reflect on your breathing patterns',
      ],
    ),

    // LEFT KIDNEY (4-5 o'clock)
    IridologyZone(
      id: 'le_kidney',
      name: 'Left Kidney',
      bodySystem: 'Urinary',
      startAngle: clockToRadians(5),
      endAngle: clockToRadians(4),
      innerRadius: 0.5,
      outerRadius: 0.7,
      description: 'Left kidney and adrenal zone',
      wellnessReflections: [
        'How is your hydration?',
        'Consider your stress levels',
        'Reflect on your body\'s rest needs',
      ],
    ),

    // SPLEEN (7-8 o'clock left eye)
    IridologyZone(
      id: 'le_spleen',
      name: 'Spleen',
      bodySystem: 'Immune',
      startAngle: clockToRadians(8),
      endAngle: clockToRadians(7),
      innerRadius: 0.4,
      outerRadius: 0.6,
      description: 'Spleen and immune function',
      wellnessReflections: [
        'How is your immune resilience?',
        'Consider rest and recovery',
        'Reflect on stress management',
      ],
    ),

    // LEFT BRAIN (11-1 o'clock)
    IridologyZone(
      id: 'le_brain',
      name: 'Left Brain Hemisphere',
      bodySystem: 'Nervous',
      startAngle: clockToRadians(1),
      endAngle: clockToRadians(11),
      innerRadius: 0.6,
      outerRadius: 0.8,
      description: 'Left brain and nervous system',
      wellnessReflections: [
        'How are your stress levels?',
        'Consider mental clarity and focus',
        'Reflect on your sleep quality',
      ],
    ),

    // LYMPHATIC RING (outer edge)
    IridologyZone(
      id: 'le_lymphatic',
      name: 'Lymphatic System',
      bodySystem: 'Immune',
      startAngle: 0,
      endAngle: 2 * pi,
      innerRadius: 0.8,
      outerRadius: 1.0,
      description: 'Lymphatic and immune zone',
      wellnessReflections: [
        'How is your overall vitality?',
        'Consider immune system support',
        'Reflect on rest and recovery',
      ],
    ),

    // INTESTINES (4-8 o'clock)
    IridologyZone(
      id: 'le_intestines',
      name: 'Intestines',
      bodySystem: 'Digestive',
      startAngle: clockToRadians(8),
      endAngle: clockToRadians(4),
      innerRadius: 0.3,
      outerRadius: 0.5,
      description: 'Intestinal zone',
      wellnessReflections: [
        'How is your digestive regularity?',
        'Consider fiber and water intake',
        'Reflect on gut-friendly foods',
      ],
    ),
  ];

  /// Get zones for specific eye
  static List<IridologyZone> getZonesForEye(bool isLeftEye) {
    return isLeftEye ? leftEyeZones : rightEyeZones;
  }

  /// Get all unique body systems
  static List<String> getAllBodySystems() {
    final systems = <String>{};
    for (final zone in [...rightEyeZones, ...leftEyeZones]) {
      systems.add(zone.bodySystem);
    }
    return systems.toList()..sort();
  }

  /// Get all zones for a specific body system
  static List<IridologyZone> getZonesBySystem(String system, bool isLeftEye) {
    final zones = getZonesForEye(isLeftEye);
    return zones.where((z) => z.bodySystem == system).toList();
  }
}
