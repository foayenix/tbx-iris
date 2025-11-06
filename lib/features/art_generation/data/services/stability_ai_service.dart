// lib/features/art_generation/data/services/stability_ai_service.dart
// Service for interacting with Stability AI API

import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/art_generation_result.dart';
import '../../../../core/constants/art_styles.dart';

/// Service for generating art from iris images using Stability AI
class StabilityAIService {
  final Dio _dio;
  final ArtGenerationConfig _config;
  final _uuid = const Uuid();

  StabilityAIService({
    required ArtGenerationConfig config,
  })  : _config = config,
        _dio = Dio(BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: Duration(seconds: config.timeoutSeconds),
          receiveTimeout: Duration(seconds: config.timeoutSeconds),
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Accept': 'application/json',
          },
        ));

  /// Generate art from an iris image using Stability AI
  ///
  /// This uses the image-to-image endpoint with the style's prompt
  Future<ArtGenerationResult> generateArt({
    required ArtGenerationRequest request,
  }) async {
    if (!_config.isConfigured) {
      return ArtGenerationResult.failure(
        id: request.id,
        style: request.style,
        originalIrisImage: request.irisImage,
        errorMessage: 'Stability AI API key not configured',
      );
    }

    final startTime = DateTime.now();

    try {
      // Prepare the request for Stability AI
      final formData = await _buildFormData(request);

      // Make the API call
      final response = await _dio.post(
        '/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
        ),
      );

      // Parse the response
      if (response.statusCode == 200) {
        final generatedImage = _parseResponse(response.data);
        final generationTimeMs = DateTime.now().difference(startTime).inMilliseconds;

        return ArtGenerationResult.success(
          id: request.id,
          style: request.style,
          originalIrisImage: request.irisImage,
          generatedArtImage: generatedImage,
          generationTimeMs: generationTimeMs,
        );
      } else {
        return ArtGenerationResult.failure(
          id: request.id,
          style: request.style,
          originalIrisImage: request.irisImage,
          errorMessage: 'API returned status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return ArtGenerationResult.failure(
        id: request.id,
        style: request.style,
        originalIrisImage: request.irisImage,
        errorMessage: _handleDioError(e),
      );
    } catch (e) {
      return ArtGenerationResult.failure(
        id: request.id,
        style: request.style,
        originalIrisImage: request.irisImage,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  /// Build multipart form data for the API request
  Future<FormData> _buildFormData(ArtGenerationRequest request) async {
    // Build the full prompt with style prompt + iris-specific enhancements
    final fullPrompt = _buildFullPrompt(request.style);

    return FormData.fromMap({
      'init_image': MultipartFile.fromBytes(
        request.irisImage,
        filename: 'iris.png',
      ),
      'init_image_mode': 'IMAGE_STRENGTH',
      'image_strength': request.strength,
      'text_prompts[0][text]': fullPrompt,
      'text_prompts[0][weight]': 1.0,
      'cfg_scale': 7.0, // How strictly to follow the prompt
      'samples': 1, // Number of images to generate
      'steps': request.steps,
      if (request.seed > 0) 'seed': request.seed,
      'style_preset': _mapStylePreset(request.style),
    });
  }

  /// Build full prompt with iris-specific enhancements
  String _buildFullPrompt(ArtStyle style) {
    // Combine style prompt with iris-specific guidance
    final basePrompt = style.prompt;
    final irisGuidance = 'circular iris pattern, eye-like structure, radial symmetry, intricate details';

    return '$basePrompt, $irisGuidance, highly detailed, professional quality, 4k';
  }

  /// Map our art style to Stability AI style presets
  String? _mapStylePreset(ArtStyle style) {
    // Stability AI has built-in style presets we can leverage
    switch (style.id) {
      case 'neon_cyber':
        return 'neon-punk';
      case 'watercolor_dream':
        return 'analog-film';
      case 'oil_painting':
        return 'cinematic';
      case 'minimalist':
        return 'line-art';
      case 'cosmic_galaxy':
        return 'digital-art';
      case 'geometric_gold':
        return 'low-poly';
      case 'botanical_life':
        return 'photographic';
      case 'stained_glass':
        return 'tile-texture';
      case 'abstract_emotion':
        return 'fantasy-art';
      case 'mandala_zen':
        return 'origami';
      case 'impressionist':
        return 'analog-film';
      case 'surreal_dream':
        return '3d-model';
      default:
        return null;
    }
  }

  /// Parse the API response and extract the generated image
  Uint8List _parseResponse(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('artifacts')) {
      final artifacts = responseData['artifacts'] as List;
      if (artifacts.isNotEmpty) {
        final artifact = artifacts[0];
        if (artifact is Map && artifact.containsKey('base64')) {
          final base64String = artifact['base64'] as String;
          return base64Decode(base64String);
        }
      }
    }
    throw Exception('Invalid response format from Stability AI');
  }

  /// Handle Dio errors with user-friendly messages
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Invalid API key. Please check your configuration.';
        } else if (statusCode == 402) {
          return 'Insufficient credits. Please upgrade your Stability AI plan.';
        } else if (statusCode == 429) {
          return 'Rate limit exceeded. Please try again later.';
        } else if (statusCode == 500) {
          return 'Stability AI server error. Please try again later.';
        }
        return 'API error (${statusCode ?? 'unknown'})';

      case DioExceptionType.cancel:
        return 'Request cancelled';

      case DioExceptionType.connectionError:
        return 'No internet connection';

      case DioExceptionType.unknown:
      default:
        return 'Network error: ${error.message}';
    }
  }

  /// Generate art with mock/demo mode (for testing without API key)
  ///
  /// This creates a simple filtered version of the iris image for demo purposes
  Future<ArtGenerationResult> generateArtMock({
    required ArtGenerationRequest request,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real implementation, this would apply basic image filters
    // For now, just return the original image as the "generated" art
    // In production, you could use the image package to apply filters

    return ArtGenerationResult.success(
      id: request.id,
      style: request.style,
      originalIrisImage: request.irisImage,
      generatedArtImage: request.irisImage, // Mock: return original
      generationTimeMs: 2000,
    );
  }

  /// Check if the service is properly configured
  bool isConfigured() {
    return _config.isConfigured;
  }

  /// Get configuration status and details
  Map<String, dynamic> getConfigStatus() {
    return {
      'configured': _config.isConfigured,
      'baseUrl': _config.baseUrl,
      'timeout': _config.timeoutSeconds,
      'caching': _config.enableCaching,
    };
  }
}
