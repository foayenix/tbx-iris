// lib/features/history/data/services/backup_restore_service.dart
// Service for backing up and restoring scan history

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/scan_history_entry.dart';
import 'history_storage_service.dart';

/// Service for backup and restore operations
class BackupRestoreService {
  final HistoryStorageService _storageService;

  BackupRestoreService({required HistoryStorageService storageService})
      : _storageService = storageService;

  /// Create a full backup of all scan history
  Future<BackupResult> createBackup({
    bool includeImages = true,
    bool compress = true,
  }) async {
    try {
      final startTime = DateTime.now();

      // Get all scans
      final scans = await _storageService.getAllScans();
      if (scans.isEmpty) {
        return BackupResult.failure('No scans to backup');
      }

      // Create backup data
      final backupData = {
        'version': '1.0',
        'created': DateTime.now().toIso8601String(),
        'deviceInfo': await _getDeviceInfo(),
        'scanCount': scans.length,
        'includeImages': includeImages,
        'scans': scans.map((s) => _scanToBackupFormat(s, includeImages)).toList(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to file
      final file = await _saveBackupFile(jsonString);
      final fileSize = await file.length();
      final duration = DateTime.now().difference(startTime);

      return BackupResult.success(
        filePath: file.path,
        scanCount: scans.length,
        fileSize: fileSize,
        duration: duration,
      );
    } catch (e) {
      return BackupResult.failure('Backup failed: $e');
    }
  }

  /// Restore from backup file
  Future<RestoreResult> restoreFromBackup({
    required String filePath,
    RestoreMode mode = RestoreMode.merge,
  }) async {
    try {
      final startTime = DateTime.now();

      // Read backup file
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult.failure('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup
      final validation = _validateBackup(backupData);
      if (!validation.isValid) {
        return RestoreResult.failure(validation.error!);
      }

      // Handle restore mode
      if (mode == RestoreMode.replace) {
        await _storageService.clearAllHistory();
      }

      // Restore scans
      final scansData = backupData['scans'] as List;
      var restored = 0;
      var skipped = 0;
      var failed = 0;

      for (var scanData in scansData) {
        try {
          final scan = _scanFromBackupFormat(scanData);

          // Check if scan already exists (in merge mode)
          if (mode == RestoreMode.merge) {
            final existing = await _storageService.getScan(scan.id);
            if (existing != null) {
              skipped++;
              continue;
            }
          }

          await _storageService.saveScan(scan);
          restored++;
        } catch (e) {
          print('Failed to restore scan: $e');
          failed++;
        }
      }

      final duration = DateTime.now().difference(startTime);

      return RestoreResult.success(
        restoredCount: restored,
        skippedCount: skipped,
        failedCount: failed,
        duration: duration,
      );
    } catch (e) {
      return RestoreResult.failure('Restore failed: $e');
    }
  }

  /// Share backup file
  Future<void> shareBackup(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/json')],
        subject: 'Iris Wellness Backup',
        text: 'My Iris wellness scan history backup',
      );
    } catch (e) {
      throw Exception('Failed to share backup: $e');
    }
  }

  /// Get list of available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backups = <BackupInfo>[];

      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final stat = await entity.stat();
            final content = await entity.readAsString();
            final data = jsonDecode(content) as Map<String, dynamic>;

            backups.add(BackupInfo(
              filePath: entity.path,
              created: DateTime.parse(data['created'] as String),
              scanCount: data['scanCount'] as int,
              fileSize: stat.size,
              includesImages: data['includeImages'] as bool? ?? false,
            ));
          } catch (e) {
            // Skip invalid backup files
            print('Skipping invalid backup: ${entity.path}');
          }
        }
      }

      // Sort by date (newest first)
      backups.sort((a, b) => b.created.compareTo(a.created));

      return backups;
    } catch (e) {
      throw Exception('Failed to get backups: $e');
    }
  }

  /// Delete a backup file
  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  /// Create auto-backup if needed
  Future<BackupResult?> createAutoBackup({
    required AutoBackupSettings settings,
  }) async {
    if (!settings.enabled) return null;

    try {
      // Check if enough time has passed since last backup
      final lastBackup = await _getLastBackupTime();
      if (lastBackup != null) {
        final daysSinceBackup = DateTime.now().difference(lastBackup).inDays;
        if (daysSinceBackup < settings.intervalDays) {
          return null; // Too soon for auto-backup
        }
      }

      // Check scan count threshold
      final scanCount = await _storageService.getTotalScans();
      if (scanCount < settings.minScansForBackup) {
        return null; // Not enough scans
      }

      // Create backup
      final result = await createBackup(
        includeImages: settings.includeImages,
        compress: true,
      );

      // Clean old backups if needed
      if (result.isSuccess && settings.maxBackups > 0) {
        await _cleanOldBackups(settings.maxBackups);
      }

      return result;
    } catch (e) {
      return BackupResult.failure('Auto-backup failed: $e');
    }
  }

  // Helper methods

  Future<File> _saveBackupFile(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'iris_backup_$timestamp.json';
    final file = File('${backupDir.path}/$fileName');

    await file.writeAsString(jsonString);
    return file;
  }

  Map<String, dynamic> _scanToBackupFormat(
    ScanHistoryEntry scan,
    bool includeImages,
  ) {
    final data = <String, dynamic>{
      'id': scan.id,
      'timestamp': scan.timestamp.toIso8601String(),
      'metadata': scan.metadata.toJson(),
      'totalInsights': scan.totalInsights,
      'bodySystems': scan.allBodySystems.toList(),
      'hasArt': scan.hasArtGenerations,
      'artCount': scan.artGenerationIds.length,
    };

    if (includeImages) {
      data['leftIrisImage'] = base64Encode(scan.leftIrisImage);
      if (scan.rightIrisImage != null) {
        data['rightIrisImage'] = base64Encode(scan.rightIrisImage!);
      }
    }

    return data;
  }

  ScanHistoryEntry _scanFromBackupFormat(Map<String, dynamic> data) {
    return ScanHistoryEntry(
      id: data['id'] as String,
      timestamp: DateTime.parse(data['timestamp'] as String),
      leftIrisImage: data.containsKey('leftIrisImage')
          ? base64Decode(data['leftIrisImage'] as String)
          : Uint8List(0),
      rightIrisImage: data.containsKey('rightIrisImage')
          ? base64Decode(data['rightIrisImage'] as String)
          : null,
      metadata: ScanMetadata.fromJson(data['metadata'] as Map<String, dynamic>),
    );
  }

  ValidationResult _validateBackup(Map<String, dynamic> backupData) {
    // Check version
    if (!backupData.containsKey('version')) {
      return ValidationResult.invalid('Missing version');
    }

    // Check required fields
    if (!backupData.containsKey('scans')) {
      return ValidationResult.invalid('Missing scans data');
    }

    // Check scans format
    final scans = backupData['scans'];
    if (scans is! List) {
      return ValidationResult.invalid('Invalid scans format');
    }

    return ValidationResult.valid();
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
  }

  Future<DateTime?> _getLastBackupTime() async {
    final backups = await getAvailableBackups();
    if (backups.isEmpty) return null;
    return backups.first.created;
  }

  Future<void> _cleanOldBackups(int maxBackups) async {
    final backups = await getAvailableBackups();
    if (backups.length <= maxBackups) return;

    // Delete oldest backups
    for (var i = maxBackups; i < backups.length; i++) {
      await deleteBackup(backups[i].filePath);
    }
  }
}

// Import types
import 'dart:typed_data';

/// Backup result
class BackupResult {
  final bool isSuccess;
  final String? filePath;
  final int? scanCount;
  final int? fileSize;
  final Duration? duration;
  final String? error;

  const BackupResult({
    required this.isSuccess,
    this.filePath,
    this.scanCount,
    this.fileSize,
    this.duration,
    this.error,
  });

  factory BackupResult.success({
    required String filePath,
    required int scanCount,
    required int fileSize,
    required Duration duration,
  }) {
    return BackupResult(
      isSuccess: true,
      filePath: filePath,
      scanCount: scanCount,
      fileSize: fileSize,
      duration: duration,
    );
  }

  factory BackupResult.failure(String error) {
    return BackupResult(
      isSuccess: false,
      error: error,
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Restore result
class RestoreResult {
  final bool isSuccess;
  final int? restoredCount;
  final int? skippedCount;
  final int? failedCount;
  final Duration? duration;
  final String? error;

  const RestoreResult({
    required this.isSuccess,
    this.restoredCount,
    this.skippedCount,
    this.failedCount,
    this.duration,
    this.error,
  });

  factory RestoreResult.success({
    required int restoredCount,
    required int skippedCount,
    required int failedCount,
    required Duration duration,
  }) {
    return RestoreResult(
      isSuccess: true,
      restoredCount: restoredCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
      duration: duration,
    );
  }

  factory RestoreResult.failure(String error) {
    return RestoreResult(
      isSuccess: false,
      error: error,
    );
  }

  int get totalCount => (restoredCount ?? 0) + (skippedCount ?? 0) + (failedCount ?? 0);
}

/// Restore mode
enum RestoreMode {
  merge, // Add new scans, keep existing
  replace, // Delete all and restore
}

/// Backup info
class BackupInfo {
  final String filePath;
  final DateTime created;
  final int scanCount;
  final int fileSize;
  final bool includesImages;

  const BackupInfo({
    required this.filePath,
    required this.created,
    required this.scanCount,
    required this.fileSize,
    required this.includesImages,
  });

  String get fileName => filePath.split('/').last;

  String get fileSizeFormatted {
    final kb = fileSize / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Auto-backup settings
class AutoBackupSettings {
  final bool enabled;
  final int intervalDays;
  final int minScansForBackup;
  final bool includeImages;
  final int maxBackups;

  const AutoBackupSettings({
    this.enabled = false,
    this.intervalDays = 7,
    this.minScansForBackup = 5,
    this.includeImages = true,
    this.maxBackups = 5,
  });
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({
    required this.isValid,
    this.error,
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(String error) {
    return ValidationResult(isValid: false, error: error);
  }
}
