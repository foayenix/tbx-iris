// lib/features/history/data/services/advanced_search_service.dart
// Advanced search service with full-text search capabilities

import '../../domain/entities/scan_history_entry.dart';
import '../../../iris_analysis/domain/entities/iridology_analysis.dart';

/// Advanced search service for scan history
class AdvancedSearchService {
  /// Search scans with full-text query
  Future<List<ScanHistoryEntry>> searchScans({
    required List<ScanHistoryEntry> scans,
    required String query,
    SearchOptions? options,
  }) async {
    if (query.isEmpty) return scans;

    final lowerQuery = query.toLowerCase();
    final results = <ScanHistoryEntry>[];

    for (var scan in scans) {
      if (_matchesScan(scan, lowerQuery, options ?? SearchOptions.defaults())) {
        results.add(scan);
      }
    }

    return results;
  }

  /// Check if scan matches query
  bool _matchesScan(
    ScanHistoryEntry scan,
    String lowerQuery,
    SearchOptions options,
  ) {
    // Search in tags
    if (options.searchTags) {
      for (var tag in scan.metadata.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }
    }

    // Search in notes
    if (options.searchNotes && scan.metadata.notes != null) {
      if (scan.metadata.notes!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
    }

    // Search in body systems
    if (options.searchBodySystems) {
      for (var system in scan.allBodySystems) {
        if (system.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }
    }

    // Search in insights
    if (options.searchInsights) {
      if (scan.leftEyeAnalysis != null) {
        if (_matchesAnalysis(scan.leftEyeAnalysis!, lowerQuery)) {
          return true;
        }
      }
      if (scan.rightEyeAnalysis != null) {
        if (_matchesAnalysis(scan.rightEyeAnalysis!, lowerQuery)) {
          return true;
        }
      }
    }

    // Search by date
    if (options.searchDate) {
      final dateStr = _formatDate(scan.timestamp).toLowerCase();
      if (dateStr.contains(lowerQuery)) {
        return true;
      }
    }

    return false;
  }

  /// Check if analysis matches query
  bool _matchesAnalysis(IridologyAnalysis analysis, String lowerQuery) {
    // Search in insight titles
    for (var insight in analysis.insights) {
      if (insight.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      // Search in insight descriptions
      if (insight.description.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      // Search in reflection prompts
      for (var prompt in insight.reflectionPrompts) {
        if (prompt.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Advanced search with multiple criteria
  Future<List<ScanHistoryEntry>> advancedSearch({
    required List<ScanHistoryEntry> scans,
    AdvancedSearchCriteria? criteria,
  }) async {
    if (criteria == null) return scans;

    var results = List<ScanHistoryEntry>.from(scans);

    // Apply quality filter
    if (criteria.minQuality != null) {
      results = results
          .where((s) => s.metadata.qualityScore >= criteria.minQuality!)
          .toList();
    }
    if (criteria.maxQuality != null) {
      results = results
          .where((s) => s.metadata.qualityScore <= criteria.maxQuality!)
          .toList();
    }

    // Apply date range filter
    if (criteria.startDate != null) {
      results = results
          .where((s) => s.timestamp.isAfter(criteria.startDate!))
          .toList();
    }
    if (criteria.endDate != null) {
      results = results
          .where((s) => s.timestamp.isBefore(criteria.endDate!))
          .toList();
    }

    // Apply insights filter
    if (criteria.minInsights != null) {
      results = results
          .where((s) => s.totalInsights >= criteria.minInsights!)
          .toList();
    }
    if (criteria.maxInsights != null) {
      results = results
          .where((s) => s.totalInsights <= criteria.maxInsights!)
          .toList();
    }

    // Apply body systems filter
    if (criteria.bodySystems != null && criteria.bodySystems!.isNotEmpty) {
      results = results.where((scan) {
        return criteria.bodySystems!.any(
          (system) => scan.allBodySystems.contains(system),
        );
      }).toList();
    }

    // Apply tags filter
    if (criteria.tags != null && criteria.tags!.isNotEmpty) {
      results = results.where((scan) {
        return criteria.tags!.any(
          (tag) => scan.metadata.tags.contains(tag),
        );
      }).toList();
    }

    // Apply art generation filter
    if (criteria.hasArt != null) {
      results = results
          .where((s) => s.hasArtGenerations == criteria.hasArt)
          .toList();
    }

    // Apply text search
    if (criteria.textQuery != null && criteria.textQuery!.isNotEmpty) {
      results = await searchScans(
        scans: results,
        query: criteria.textQuery!,
        options: criteria.searchOptions,
      );
    }

    return results;
  }

  /// Get search suggestions based on partial query
  Future<List<String>> getSearchSuggestions({
    required List<ScanHistoryEntry> scans,
    required String partialQuery,
    int maxSuggestions = 10,
  }) async {
    if (partialQuery.isEmpty) return [];

    final lowerQuery = partialQuery.toLowerCase();
    final suggestions = <String>{};

    // Collect suggestions from tags
    for (var scan in scans) {
      for (var tag in scan.metadata.tags) {
        if (tag.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(tag);
        }
      }
    }

    // Collect suggestions from body systems
    for (var scan in scans) {
      for (var system in scan.allBodySystems) {
        if (system.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(system);
        }
      }
    }

    // Collect suggestions from insight titles
    for (var scan in scans) {
      if (scan.leftEyeAnalysis != null) {
        for (var insight in scan.leftEyeAnalysis!.insights) {
          if (insight.title.toLowerCase().startsWith(lowerQuery)) {
            suggestions.add(insight.title);
          }
        }
      }
    }

    return suggestions.take(maxSuggestions).toList();
  }

  /// Group search results by criteria
  Map<String, List<ScanHistoryEntry>> groupSearchResults({
    required List<ScanHistoryEntry> results,
    required GroupBy groupBy,
  }) {
    final grouped = <String, List<ScanHistoryEntry>>{};

    for (var scan in results) {
      final key = _getGroupKey(scan, groupBy);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(scan);
    }

    return grouped;
  }

  /// Get grouping key for scan
  String _getGroupKey(ScanHistoryEntry scan, GroupBy groupBy) {
    switch (groupBy) {
      case GroupBy.date:
        return _formatDate(scan.timestamp);
      case GroupBy.month:
        return _formatMonth(scan.timestamp);
      case GroupBy.quality:
        return _getQualityBucket(scan.metadata.qualityScore);
      case GroupBy.insightCount:
        return _getInsightBucket(scan.totalInsights);
      case GroupBy.bodySystem:
        return scan.allBodySystems.isNotEmpty
            ? scan.allBodySystems.first
            : 'None';
      case GroupBy.tag:
        return scan.metadata.tags.isNotEmpty ? scan.metadata.tags.first : 'Untagged';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMonth(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getQualityBucket(double quality) {
    if (quality >= 0.8) return 'Excellent (80-100%)';
    if (quality >= 0.6) return 'Good (60-80%)';
    if (quality >= 0.4) return 'Fair (40-60%)';
    return 'Poor (<40%)';
  }

  String _getInsightBucket(int count) {
    if (count >= 10) return '10+ insights';
    if (count >= 5) return '5-9 insights';
    if (count >= 1) return '1-4 insights';
    return 'No insights';
  }

  /// Highlight matching text in search results
  List<TextMatch> highlightMatches({
    required String text,
    required String query,
  }) {
    if (query.isEmpty) {
      return [TextMatch(text: text, isMatch: false)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextMatch>[];

    var lastIndex = 0;
    var index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add non-matching text before match
      if (index > lastIndex) {
        matches.add(TextMatch(
          text: text.substring(lastIndex, index),
          isMatch: false,
        ));
      }

      // Add matching text
      matches.add(TextMatch(
        text: text.substring(index, index + query.length),
        isMatch: true,
      ));

      lastIndex = index + query.length;
      index = lowerText.indexOf(lowerQuery, lastIndex);
    }

    // Add remaining non-matching text
    if (lastIndex < text.length) {
      matches.add(TextMatch(
        text: text.substring(lastIndex),
        isMatch: false,
      ));
    }

    return matches;
  }
}

/// Search options
class SearchOptions {
  final bool searchTags;
  final bool searchNotes;
  final bool searchBodySystems;
  final bool searchInsights;
  final bool searchDate;

  const SearchOptions({
    this.searchTags = true,
    this.searchNotes = true,
    this.searchBodySystems = true,
    this.searchInsights = true,
    this.searchDate = true,
  });

  factory SearchOptions.defaults() => const SearchOptions();

  factory SearchOptions.tagsOnly() => const SearchOptions(
        searchTags: true,
        searchNotes: false,
        searchBodySystems: false,
        searchInsights: false,
        searchDate: false,
      );

  factory SearchOptions.insightsOnly() => const SearchOptions(
        searchTags: false,
        searchNotes: false,
        searchBodySystems: false,
        searchInsights: true,
        searchDate: false,
      );
}

/// Advanced search criteria
class AdvancedSearchCriteria {
  final double? minQuality;
  final double? maxQuality;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minInsights;
  final int? maxInsights;
  final List<String>? bodySystems;
  final List<String>? tags;
  final bool? hasArt;
  final String? textQuery;
  final SearchOptions? searchOptions;

  const AdvancedSearchCriteria({
    this.minQuality,
    this.maxQuality,
    this.startDate,
    this.endDate,
    this.minInsights,
    this.maxInsights,
    this.bodySystems,
    this.tags,
    this.hasArt,
    this.textQuery,
    this.searchOptions,
  });

  bool get hasFilters =>
      minQuality != null ||
      maxQuality != null ||
      startDate != null ||
      endDate != null ||
      minInsights != null ||
      maxInsights != null ||
      (bodySystems != null && bodySystems!.isNotEmpty) ||
      (tags != null && tags!.isNotEmpty) ||
      hasArt != null ||
      (textQuery != null && textQuery!.isNotEmpty);
}

/// Group by options
enum GroupBy {
  date,
  month,
  quality,
  insightCount,
  bodySystem,
  tag,
}

/// Text match for highlighting
class TextMatch {
  final String text;
  final bool isMatch;

  const TextMatch({
    required this.text,
    required this.isMatch,
  });
}
