// lib/features/history/data/services/export_service.dart
// Service for exporting wellness reports in various formats

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/scan_history_entry.dart';
import '../../../iris_analysis/domain/entities/iridology_analysis.dart';

/// Service for exporting wellness data
class ExportService {
  /// Export formats
  static const String formatJson = 'json';
  static const String formatCsv = 'csv';
  static const String formatText = 'txt';

  /// Export a single scan to JSON
  Future<String> exportScanToJson(ScanHistoryEntry scan) async {
    final data = {
      'exportVersion': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'scan': _scanToMap(scan),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export multiple scans to JSON
  Future<String> exportScansToJson(List<ScanHistoryEntry> scans) async {
    final data = {
      'exportVersion': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'totalScans': scans.length,
      'scans': scans.map(_scanToMap).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export analysis to text format
  Future<String> exportAnalysisToText(IridologyAnalysis analysis) async {
    final buffer = StringBuffer();

    buffer.writeln('='.padRight(50, '='));
    buffer.writeln('IRIS WELLNESS ANALYSIS REPORT');
    buffer.writeln('='.padRight(50, '='));
    buffer.writeln();
    buffer.writeln('Generated: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('Analysis ID: ${analysis.id}');
    buffer.writeln('Eye: ${analysis.isLeftEye ? 'Left' : 'Right'}');
    buffer.writeln('Date: ${_formatDateTime(analysis.timestamp)}');
    buffer.writeln('Confidence: ${(analysis.analysisConfidence * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    // Color Profile
    buffer.writeln('-'.padRight(50, '-'));
    buffer.writeln('IRIS COLOR PROFILE');
    buffer.writeln('-'.padRight(50, '-'));
    buffer.writeln('Dominant Color: ${analysis.overallColorProfile.dominantColor}');
    buffer.writeln('Description: ${analysis.overallColorProfile.description}');
    buffer.writeln();

    // Insights
    buffer.writeln('-'.padRight(50, '-'));
    buffer.writeln('WELLNESS INSIGHTS (${analysis.insights.length})');
    buffer.writeln('-'.padRight(50, '-'));
    buffer.writeln();

    for (var i = 0; i < analysis.insights.length; i++) {
      final insight = analysis.insights[i];
      buffer.writeln('${i + 1}. ${insight.title}');
      buffer.writeln('   Category: ${insight.category.displayName}');
      buffer.writeln('   Body System: ${insight.bodySystem}');
      buffer.writeln('   Level: ${insight.confidenceLevel}');
      buffer.writeln();
      buffer.writeln('   ${insight.description}');
      buffer.writeln();

      if (insight.reflectionPrompts.isNotEmpty) {
        buffer.writeln('   Reflection Prompts:');
        for (var prompt in insight.reflectionPrompts) {
          buffer.writeln('   - $prompt');
        }
        buffer.writeln();
      }
    }

    // Body Systems
    buffer.writeln('-'.padRight(50, '-'));
    buffer.writeln('BODY SYSTEMS ANALYZED');
    buffer.writeln('-'.padRight(50, '-'));
    for (var system in analysis.bodySystems) {
      final systemInsights = analysis.getInsightsForSystem(system);
      buffer.writeln('• $system (${systemInsights.length} insights)');
    }
    buffer.writeln();

    // Zones
    buffer.writeln('-'.padRight(50, '-'));
    buffer.writeln('IRIS ZONES ANALYZED (${analysis.zoneAnalyses.length})');
    buffer.writeln('-'.padRight(50, '-'));
    for (var zoneAnalysis in analysis.zoneAnalyses) {
      buffer.writeln('• ${zoneAnalysis.zone.bodySystem}');
      buffer.writeln('  Significance: ${(zoneAnalysis.significanceScore * 100).toStringAsFixed(0)}%');
      if (zoneAnalysis.observations.isNotEmpty) {
        buffer.writeln('  Observations: ${zoneAnalysis.observations.join(', ')}');
      }
    }
    buffer.writeln();

    // Disclaimer
    buffer.writeln('='.padRight(50, '='));
    buffer.writeln('DISCLAIMER');
    buffer.writeln('='.padRight(50, '='));
    buffer.writeln('This analysis is for wellness education and reflection');
    buffer.writeln('purposes only. It is NOT a medical diagnosis or advice.');
    buffer.writeln('Please consult qualified healthcare professionals for');
    buffer.writeln('medical concerns.');
    buffer.writeln('='.padRight(50, '='));

    return buffer.toString();
  }

  /// Export scan history to CSV
  Future<String> exportScansToCSV(List<ScanHistoryEntry> scans) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Date,Time,Quality Score,Total Insights,Body Systems,Has Art,Tags,Notes',
    );

    // Rows
    for (var scan in scans) {
      final date = _formatDate(scan.timestamp);
      final time = _formatTime(scan.timestamp);
      final quality = (scan.metadata.qualityScore * 100).toStringAsFixed(0);
      final insights = scan.totalInsights;
      final systems = scan.allBodySystems.join(';');
      final hasArt = scan.hasArtGenerations ? 'Yes' : 'No';
      final tags = scan.metadata.tags.join(';');
      final notes = _escapeCsvField(scan.metadata.notes ?? '');

      buffer.writeln('$date,$time,$quality,$insights,"$systems",$hasArt,"$tags","$notes"');
    }

    return buffer.toString();
  }

  /// Save and share a report
  Future<void> saveAndShareReport({
    required String content,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Iris Wellness Report',
      );
    } catch (e) {
      throw Exception('Failed to save and share report: $e');
    }
  }

  /// Generate and share scan report
  Future<void> exportAndShareScan({
    required ScanHistoryEntry scan,
    required String format,
  }) async {
    String content;
    String fileName;
    String mimeType;

    switch (format) {
      case formatJson:
        content = await exportScanToJson(scan);
        fileName = 'iris_scan_${scan.id}.json';
        mimeType = 'application/json';
        break;

      case formatText:
        if (scan.primaryAnalysis == null) {
          throw Exception('No analysis data available for text export');
        }
        content = await exportAnalysisToText(scan.primaryAnalysis!);
        fileName = 'iris_analysis_${scan.id}.txt';
        mimeType = 'text/plain';
        break;

      default:
        throw Exception('Unsupported format: $format');
    }

    await saveAndShareReport(
      content: content,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Generate and share multiple scans report
  Future<void> exportAndShareScans({
    required List<ScanHistoryEntry> scans,
    required String format,
  }) async {
    String content;
    String fileName;
    String mimeType;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    switch (format) {
      case formatJson:
        content = await exportScansToJson(scans);
        fileName = 'iris_scans_$timestamp.json';
        mimeType = 'application/json';
        break;

      case formatCsv:
        content = await exportScansToCSV(scans);
        fileName = 'iris_scans_$timestamp.csv';
        mimeType = 'text/csv';
        break;

      default:
        throw Exception('Unsupported format: $format');
    }

    await saveAndShareReport(
      content: content,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  // Helper methods

  Map<String, dynamic> _scanToMap(ScanHistoryEntry scan) {
    return {
      'id': scan.id,
      'timestamp': scan.timestamp.toIso8601String(),
      'qualityScore': scan.metadata.qualityScore,
      'totalInsights': scan.totalInsights,
      'bodySystems': scan.allBodySystems.toList(),
      'hasArt': scan.hasArtGenerations,
      'artCount': scan.artGenerationIds.length,
      'tags': scan.metadata.tags,
      'notes': scan.metadata.notes,
      'metadata': {
        'deviceModel': scan.metadata.deviceModel,
        'appVersion': scan.metadata.appVersion,
        'wasShared': scan.metadata.wasShared,
      },
    };
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${_formatTime(dt)}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return field.replaceAll('"', '""');
    }
    return field;
  }
}

/// Export format options
class ExportFormat {
  final String id;
  final String name;
  final String description;
  final String extension;
  final IconData icon;

  const ExportFormat({
    required this.id,
    required this.name,
    required this.description,
    required this.extension,
    required this.icon,
  });

  static const json = ExportFormat(
    id: 'json',
    name: 'JSON',
    description: 'Structured data format',
    extension: 'json',
    icon: Icons.code,
  );

  static const csv = ExportFormat(
    id: 'csv',
    name: 'CSV',
    description: 'Spreadsheet format',
    extension: 'csv',
    icon: Icons.table_chart,
  );

  static const text = ExportFormat(
    id: 'txt',
    name: 'Text',
    description: 'Readable text report',
    extension: 'txt',
    icon: Icons.text_snippet,
  );

  static const List<ExportFormat> allFormats = [json, csv, text];
}

// Import IconData
import 'package:flutter/material.dart';
