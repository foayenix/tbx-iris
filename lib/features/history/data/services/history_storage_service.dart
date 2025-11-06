// lib/features/history/data/services/history_storage_service.dart
// Service for persisting scan history locally using Hive

import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/scan_history_entry.dart';

/// Service for managing scan history storage
class HistoryStorageService {
  static const String _boxName = 'scan_history';
  static const String _artBoxName = 'art_history';

  Box<Map>? _historyBox;
  Box<Map>? _artBox;
  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      final appDocDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocDir.path);

      // Open boxes
      _historyBox = await Hive.openBox<Map>(_boxName);
      _artBox = await Hive.openBox<Map>(_artBoxName);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize history storage: $e');
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('HistoryStorageService not initialized. Call initialize() first.');
    }
  }

  /// Save a scan entry to history
  Future<void> saveScan(ScanHistoryEntry entry) async {
    _ensureInitialized();

    try {
      final json = entry.toJson();
      await _historyBox!.put(entry.id, json);
    } catch (e) {
      throw Exception('Failed to save scan: $e');
    }
  }

  /// Get a specific scan by ID
  Future<ScanHistoryEntry?> getScan(String id) async {
    _ensureInitialized();

    try {
      final json = _historyBox!.get(id);
      if (json == null) return null;

      return ScanHistoryEntry.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      throw Exception('Failed to get scan: $e');
    }
  }

  /// Get all scans
  Future<List<ScanHistoryEntry>> getAllScans() async {
    _ensureInitialized();

    try {
      final entries = <ScanHistoryEntry>[];

      for (var key in _historyBox!.keys) {
        final json = _historyBox!.get(key);
        if (json != null) {
          try {
            entries.add(ScanHistoryEntry.fromJson(Map<String, dynamic>.from(json)));
          } catch (e) {
            // Skip corrupted entries
            print('Warning: Skipping corrupted entry $key: $e');
          }
        }
      }

      return entries;
    } catch (e) {
      throw Exception('Failed to get all scans: $e');
    }
  }

  /// Get scans with filter and sort
  Future<List<ScanHistoryEntry>> getScans({
    HistoryFilter? filter,
    HistorySortBy sortBy = HistorySortBy.dateNewest,
    int? limit,
  }) async {
    _ensureInitialized();

    try {
      var scans = await getAllScans();

      // Apply filter
      if (filter != null) {
        scans = scans.where((scan) => filter.matches(scan)).toList();
      }

      // Apply sort
      scans.sort((a, b) {
        switch (sortBy) {
          case HistorySortBy.dateNewest:
            return b.timestamp.compareTo(a.timestamp);
          case HistorySortBy.dateOldest:
            return a.timestamp.compareTo(b.timestamp);
          case HistorySortBy.qualityHighest:
            return b.metadata.qualityScore.compareTo(a.metadata.qualityScore);
          case HistorySortBy.qualityLowest:
            return a.metadata.qualityScore.compareTo(b.metadata.qualityScore);
          case HistorySortBy.insightsMost:
            return b.totalInsights.compareTo(a.totalInsights);
          case HistorySortBy.insightsLeast:
            return a.totalInsights.compareTo(b.totalInsights);
        }
      });

      // Apply limit
      if (limit != null && scans.length > limit) {
        scans = scans.sublist(0, limit);
      }

      return scans;
    } catch (e) {
      throw Exception('Failed to get scans with filter: $e');
    }
  }

  /// Delete a scan
  Future<void> deleteScan(String id) async {
    _ensureInitialized();

    try {
      await _historyBox!.delete(id);

      // Also delete associated art generations
      final artKeys = _artBox!.keys.where((key) {
        final art = _artBox!.get(key);
        return art != null && art['scanId'] == id;
      }).toList();

      for (var key in artKeys) {
        await _artBox!.delete(key);
      }
    } catch (e) {
      throw Exception('Failed to delete scan: $e');
    }
  }

  /// Delete multiple scans
  Future<void> deleteScans(List<String> ids) async {
    _ensureInitialized();

    try {
      for (var id in ids) {
        await deleteScan(id);
      }
    } catch (e) {
      throw Exception('Failed to delete scans: $e');
    }
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    _ensureInitialized();

    try {
      await _historyBox!.clear();
      await _artBox!.clear();
    } catch (e) {
      throw Exception('Failed to clear history: $e');
    }
  }

  /// Get total scan count
  Future<int> getTotalScans() async {
    _ensureInitialized();
    return _historyBox!.length;
  }

  /// Get scans from date range
  Future<List<ScanHistoryEntry>> getScansInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final filter = HistoryFilter(startDate: start, endDate: end);
    return getScans(filter: filter);
  }

  /// Get most recent scan
  Future<ScanHistoryEntry?> getMostRecentScan() async {
    final scans = await getScans(
      sortBy: HistorySortBy.dateNewest,
      limit: 1,
    );
    return scans.isNotEmpty ? scans.first : null;
  }

  /// Update scan metadata
  Future<void> updateScanMetadata(String id, ScanMetadata metadata) async {
    _ensureInitialized();

    try {
      final scan = await getScan(id);
      if (scan == null) {
        throw Exception('Scan not found: $id');
      }

      final updated = scan.copyWith(metadata: metadata);
      await saveScan(updated);
    } catch (e) {
      throw Exception('Failed to update scan metadata: $e');
    }
  }

  /// Add tag to scan
  Future<void> addTagToScan(String id, String tag) async {
    _ensureInitialized();

    try {
      final scan = await getScan(id);
      if (scan == null) {
        throw Exception('Scan not found: $id');
      }

      final tags = [...scan.metadata.tags];
      if (!tags.contains(tag)) {
        tags.add(tag);
        final metadata = scan.metadata.copyWith(tags: tags);
        await updateScanMetadata(id, metadata);
      }
    } catch (e) {
      throw Exception('Failed to add tag: $e');
    }
  }

  /// Remove tag from scan
  Future<void> removeTagFromScan(String id, String tag) async {
    _ensureInitialized();

    try {
      final scan = await getScan(id);
      if (scan == null) {
        throw Exception('Scan not found: $id');
      }

      final tags = [...scan.metadata.tags];
      tags.remove(tag);
      final metadata = scan.metadata.copyWith(tags: tags);
      await updateScanMetadata(id, metadata);
    } catch (e) {
      throw Exception('Failed to remove tag: $e');
    }
  }

  /// Get all unique tags
  Future<Set<String>> getAllTags() async {
    _ensureInitialized();

    try {
      final scans = await getAllScans();
      final tags = <String>{};

      for (var scan in scans) {
        tags.addAll(scan.metadata.tags);
      }

      return tags;
    } catch (e) {
      throw Exception('Failed to get all tags: $e');
    }
  }

  /// Get storage statistics
  Future<HistoryStatistics> getStatistics() async {
    _ensureInitialized();

    try {
      final scans = await getAllScans();

      if (scans.isEmpty) {
        return HistoryStatistics.empty();
      }

      final totalScans = scans.length;
      final totalInsights = scans.fold<int>(
        0,
        (sum, scan) => sum + scan.totalInsights,
      );
      final avgQuality = scans.fold<double>(
        0.0,
        (sum, scan) => sum + scan.metadata.qualityScore,
      ) / totalScans;
      final scansWithArt = scans.where((s) => s.hasArtGenerations).length;
      final oldestScan = scans.reduce(
        (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b,
      ).timestamp;
      final newestScan = scans.reduce(
        (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
      ).timestamp;

      final allSystems = <String>{};
      for (var scan in scans) {
        allSystems.addAll(scan.allBodySystems);
      }

      return HistoryStatistics(
        totalScans: totalScans,
        totalInsights: totalInsights,
        averageQuality: avgQuality,
        scansWithArt: scansWithArt,
        oldestScanDate: oldestScan,
        newestScanDate: newestScan,
        uniqueBodySystems: allSystems.length,
      );
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Export history data (for backup)
  Future<Map<String, dynamic>> exportHistory() async {
    _ensureInitialized();

    try {
      final scans = await getAllScans();
      return {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalScans': scans.length,
        'scans': scans.map((s) => s.toJson()).toList(),
      };
    } catch (e) {
      throw Exception('Failed to export history: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _historyBox?.close();
    await _artBox?.close();
    _isInitialized = false;
  }
}

/// Statistics about stored history
class HistoryStatistics {
  final int totalScans;
  final int totalInsights;
  final double averageQuality;
  final int scansWithArt;
  final DateTime oldestScanDate;
  final DateTime newestScanDate;
  final int uniqueBodySystems;

  const HistoryStatistics({
    required this.totalScans,
    required this.totalInsights,
    required this.averageQuality,
    required this.scansWithArt,
    required this.oldestScanDate,
    required this.newestScanDate,
    required this.uniqueBodySystems,
  });

  factory HistoryStatistics.empty() {
    final now = DateTime.now();
    return HistoryStatistics(
      totalScans: 0,
      totalInsights: 0,
      averageQuality: 0.0,
      scansWithArt: 0,
      oldestScanDate: now,
      newestScanDate: now,
      uniqueBodySystems: 0,
    );
  }

  Duration get timespan => newestScanDate.difference(oldestScanDate);

  double get artGenerationRate =>
      totalScans > 0 ? scansWithArt / totalScans : 0.0;

  double get averageInsightsPerScan =>
      totalScans > 0 ? totalInsights / totalScans : 0.0;
}
