// lib/features/art_generation/domain/entities/art_generation_result.dart
// Domain entities for AI art generation

import 'dart:typed_data';
import '../../../../core/constants/art_styles.dart';

/// Result of an art generation request
class ArtGenerationResult {
  final String id;
  final ArtStyle style;
  final Uint8List originalIrisImage;
  final Uint8List? generatedArtImage;
  final ArtGenerationStatus status;
  final DateTime timestamp;
  final String? errorMessage;
  final int? generationTimeMs;

  const ArtGenerationResult({
    required this.id,
    required this.style,
    required this.originalIrisImage,
    this.generatedArtImage,
    required this.status,
    required this.timestamp,
    this.errorMessage,
    this.generationTimeMs,
  });

  bool get isSuccess => status == ArtGenerationStatus.completed;
  bool get isError => status == ArtGenerationStatus.failed;
  bool get isProcessing => status == ArtGenerationStatus.processing;

  /// Create a success result
  factory ArtGenerationResult.success({
    required String id,
    required ArtStyle style,
    required Uint8List originalIrisImage,
    required Uint8List generatedArtImage,
    required int generationTimeMs,
  }) {
    return ArtGenerationResult(
      id: id,
      style: style,
      originalIrisImage: originalIrisImage,
      generatedArtImage: generatedArtImage,
      status: ArtGenerationStatus.completed,
      timestamp: DateTime.now(),
      generationTimeMs: generationTimeMs,
    );
  }

  /// Create a processing result
  factory ArtGenerationResult.processing({
    required String id,
    required ArtStyle style,
    required Uint8List originalIrisImage,
  }) {
    return ArtGenerationResult(
      id: id,
      style: style,
      originalIrisImage: originalIrisImage,
      status: ArtGenerationStatus.processing,
      timestamp: DateTime.now(),
    );
  }

  /// Create a failed result
  factory ArtGenerationResult.failure({
    required String id,
    required ArtStyle style,
    required Uint8List originalIrisImage,
    required String errorMessage,
  }) {
    return ArtGenerationResult(
      id: id,
      style: style,
      originalIrisImage: originalIrisImage,
      status: ArtGenerationStatus.failed,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  /// Copy with updated fields
  ArtGenerationResult copyWith({
    String? id,
    ArtStyle? style,
    Uint8List? originalIrisImage,
    Uint8List? generatedArtImage,
    ArtGenerationStatus? status,
    DateTime? timestamp,
    String? errorMessage,
    int? generationTimeMs,
  }) {
    return ArtGenerationResult(
      id: id ?? this.id,
      style: style ?? this.style,
      originalIrisImage: originalIrisImage ?? this.originalIrisImage,
      generatedArtImage: generatedArtImage ?? this.generatedArtImage,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
      generationTimeMs: generationTimeMs ?? this.generationTimeMs,
    );
  }
}

/// Status of art generation
enum ArtGenerationStatus {
  /// Waiting to start
  pending,

  /// Currently processing
  processing,

  /// Successfully completed
  completed,

  /// Failed with error
  failed,
}

/// Request parameters for art generation
class ArtGenerationRequest {
  final String id;
  final Uint8List irisImage;
  final ArtStyle style;
  final double strength; // 0.0 to 1.0 - how much to transform
  final int seed; // For reproducible results
  final int steps; // Number of diffusion steps (more = higher quality)

  const ArtGenerationRequest({
    required this.id,
    required this.irisImage,
    required this.style,
    this.strength = 0.7,
    this.seed = 0,
    this.steps = 30,
  });

  /// Get quality preset for free users (faster, lower quality)
  factory ArtGenerationRequest.freeQuality({
    required String id,
    required Uint8List irisImage,
    required ArtStyle style,
  }) {
    return ArtGenerationRequest(
      id: id,
      irisImage: irisImage,
      style: style,
      strength: 0.6,
      steps: 20, // Fewer steps for faster generation
    );
  }

  /// Get quality preset for pro users (slower, higher quality)
  factory ArtGenerationRequest.proQuality({
    required String id,
    required Uint8List irisImage,
    required ArtStyle style,
  }) {
    return ArtGenerationRequest(
      id: id,
      irisImage: irisImage,
      style: style,
      strength: 0.75,
      steps: 50, // More steps for better quality
    );
  }
}

/// Configuration for art generation service
class ArtGenerationConfig {
  final String apiKey;
  final String baseUrl;
  final int timeoutSeconds;
  final bool enableCaching;

  const ArtGenerationConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.stability.ai',
    this.timeoutSeconds = 120,
    this.enableCaching = true,
  });

  bool get isConfigured => apiKey.isNotEmpty;
}
