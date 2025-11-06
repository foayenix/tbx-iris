// lib/features/history/domain/entities/scan_history_entry.dart
// Domain entity for storing scan history

import 'dart:typed_data';
import '../../../iris_analysis/domain/entities/iridology_analysis.dart';
import '../../../art_generation/domain/entities/art_generation_result.dart';

/// Represents a complete scan entry in history
class ScanHistoryEntry {
  final String id;
  final DateTime timestamp;
  final Uint8List leftIrisImage;
  final Uint8List? rightIrisImage;
  final IridologyAnalysis? leftEyeAnalysis;
  final IridologyAnalysis? rightEyeAnalysis;
  final List<String> artGenerationIds; // References to art generations
  final ScanMetadata metadata;

  const ScanHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.leftIrisImage,
    this.rightIrisImage,
    this.leftEyeAnalysis,
    this.rightEyeAnalysis,
    this.artGenerationIds = const [],
    required this.metadata,
  });

  /// Get primary analysis (prefer left eye)
  IridologyAnalysis? get primaryAnalysis =>
      leftEyeAnalysis ?? rightEyeAnalysis;

  /// Check if scan has both eyes
  bool get hasBothEyes =>
      leftIrisImage != null && rightIrisImage != null;

  /// Get total number of insights across all analyses
  int get totalInsights {
    var count = 0;
    if (leftEyeAnalysis != null) count += leftEyeAnalysis!.insights.length;
    if (rightEyeAnalysis != null) count += rightEyeAnalysis!.insights.length;
    return count;
  }

  /// Get all unique body systems across analyses
  Set<String> get allBodySystems {
    final systems = <String>{};
    if (leftEyeAnalysis != null) systems.addAll(leftEyeAnalysis!.bodySystems);
    if (rightEyeAnalysis != null) systems.addAll(rightEyeAnalysis!.bodySystems);
    return systems;
  }

  /// Check if this scan has art generations
  bool get hasArtGenerations => artGenerationIds.isNotEmpty;

  /// Create a copy with updated fields
  ScanHistoryEntry copyWith({
    String? id,
    DateTime? timestamp,
    Uint8List? leftIrisImage,
    Uint8List? rightIrisImage,
    IridologyAnalysis? leftEyeAnalysis,
    IridologyAnalysis? rightEyeAnalysis,
    List<String>? artGenerationIds,
    ScanMetadata? metadata,
  }) {
    return ScanHistoryEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      leftIrisImage: leftIrisImage ?? this.leftIrisImage,
      rightIrisImage: rightIrisImage ?? this.rightIrisImage,
      leftEyeAnalysis: leftEyeAnalysis ?? this.leftEyeAnalysis,
      rightEyeAnalysis: rightEyeAnalysis ?? this.rightEyeAnalysis,
      artGenerationIds: artGenerationIds ?? this.artGenerationIds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'leftIrisImage': leftIrisImage,
      'rightIrisImage': rightIrisImage,
      'leftEyeAnalysis': leftEyeAnalysis != null
          ? _serializeAnalysis(leftEyeAnalysis!)
          : null,
      'rightEyeAnalysis': rightEyeAnalysis != null
          ? _serializeAnalysis(rightEyeAnalysis!)
          : null,
      'artGenerationIds': artGenerationIds,
      'metadata': metadata.toJson(),
    };
  }

  /// Create from JSON
  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScanHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      leftIrisImage: json['leftIrisImage'] as Uint8List,
      rightIrisImage: json['rightIrisImage'] as Uint8List?,
      leftEyeAnalysis: json['leftEyeAnalysis'] != null
          ? _deserializeAnalysis(json['leftEyeAnalysis'])
          : null,
      rightEyeAnalysis: json['rightEyeAnalysis'] != null
          ? _deserializeAnalysis(json['rightEyeAnalysis'])
          : null,
      artGenerationIds: (json['artGenerationIds'] as List?)?.cast<String>() ?? [],
      metadata: ScanMetadata.fromJson(json['metadata']),
    );
  }

  // Helper methods for analysis serialization
  static Map<String, dynamic> _serializeAnalysis(IridologyAnalysis analysis) {
    // Simplified serialization - store only essential data
    return {
      'id': analysis.id,
      'isLeftEye': analysis.isLeftEye,
      'timestamp': analysis.timestamp.toIso8601String(),
      'insightCount': analysis.insights.length,
      'bodySystems': analysis.bodySystems,
      'confidence': analysis.analysisConfidence,
      'colorType': analysis.overallColorProfile.dominantColor.toString(),
    };
  }

  static IridologyAnalysis? _deserializeAnalysis(Map<String, dynamic>? json) {
    // For full reconstruction, we'd need to store complete analysis data
    // This is a simplified version - in production, store full analysis
    if (json == null) return null;

    // Return null for now - full deserialization would be complex
    // Alternative: Store analysis as separate entries in database
    return null;
  }
}

/// Metadata about a scan
class ScanMetadata {
  final double qualityScore;
  final String deviceModel;
  final String appVersion;
  final bool wasShared;
  final List<String> tags;
  final String? notes;

  const ScanMetadata({
    required this.qualityScore,
    required this.deviceModel,
    required this.appVersion,
    this.wasShared = false,
    this.tags = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'qualityScore': qualityScore,
      'deviceModel': deviceModel,
      'appVersion': appVersion,
      'wasShared': wasShared,
      'tags': tags,
      'notes': notes,
    };
  }

  factory ScanMetadata.fromJson(Map<String, dynamic> json) {
    return ScanMetadata(
      qualityScore: json['qualityScore'] as double,
      deviceModel: json['deviceModel'] as String,
      appVersion: json['appVersion'] as String,
      wasShared: json['wasShared'] as bool? ?? false,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }

  ScanMetadata copyWith({
    double? qualityScore,
    String? deviceModel,
    String? appVersion,
    bool? wasShared,
    List<String>? tags,
    String? notes,
  }) {
    return ScanMetadata(
      qualityScore: qualityScore ?? this.qualityScore,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      wasShared: wasShared ?? this.wasShared,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }
}

/// Filter options for history
class HistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> bodySystems;
  final double? minQuality;
  final bool? hasArt;
  final List<String> tags;

  const HistoryFilter({
    this.startDate,
    this.endDate,
    this.bodySystems = const {},
    this.minQuality,
    this.hasArt,
    this.tags = const [],
  });

  /// Check if an entry matches this filter
  bool matches(ScanHistoryEntry entry) {
    // Date range
    if (startDate != null && entry.timestamp.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && entry.timestamp.isAfter(endDate!)) {
      return false;
    }

    // Body systems
    if (bodySystems.isNotEmpty) {
      final entrySystemsSet = entry.allBodySystems;
      if (!bodySystems.any((sys) => entrySystemsSet.contains(sys))) {
        return false;
      }
    }

    // Quality
    if (minQuality != null && entry.metadata.qualityScore < minQuality!) {
      return false;
    }

    // Art generation
    if (hasArt != null && entry.hasArtGenerations != hasArt) {
      return false;
    }

    // Tags
    if (tags.isNotEmpty) {
      if (!tags.any((tag) => entry.metadata.tags.contains(tag))) {
        return false;
      }
    }

    return true;
  }
}

/// Sort options for history
enum HistorySortBy {
  dateNewest,
  dateOldest,
  qualityHighest,
  qualityLowest,
  insightsMost,
  insightsLeast,
}
