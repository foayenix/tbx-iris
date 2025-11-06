// lib/features/history/presentation/screens/history_timeline_screen.dart
// Screen displaying scan history in chronological timeline

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/feature_gate.dart';
import '../../domain/entities/scan_history_entry.dart';
import '../../data/services/history_storage_service.dart';

/// Screen showing historical scan timeline
class HistoryTimelineScreen extends ConsumerStatefulWidget {
  const HistoryTimelineScreen({super.key});

  @override
  ConsumerState<HistoryTimelineScreen> createState() =>
      _HistoryTimelineScreenState();
}

class _HistoryTimelineScreenState extends ConsumerState<HistoryTimelineScreen> {
  final _historyService = HistoryStorageService();
  List<ScanHistoryEntry> _scans = [];
  HistoryStatistics? _statistics;
  bool _isLoading = true;
  HistorySortBy _sortBy = HistorySortBy.dateNewest;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      await _historyService.initialize();
      final scans = await _historyService.getScans(sortBy: _sortBy);
      final stats = await _historyService.getStatistics();

      setState(() {
        _scans = scans;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = FeatureGate.isPro(ref);
    final hasUnlimitedHistory =
        FeatureGate.isFeatureUnlocked(ref, ProFeature.unlimitedHistory);

    // Limit free users to 10 scans
    final displayScans = (!isPro && _scans.length > FeatureGate.maxFreeHistoryScans)
        ? _scans.take(FeatureGate.maxFreeHistoryScans).toList()
        : _scans;
    final hiddenCount = _scans.length - displayScans.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (!isPro)
            TextButton.icon(
              onPressed: () => _showUpgradeDialog(),
              icon: const Icon(Icons.star, color: Colors.amber, size: 20),
              label: const Text('Go Pro'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _scans.isNotEmpty ? _confirmClearHistory : null,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scans.isEmpty
              ? _EmptyHistoryView()
              : Column(
                  children: [
                    // Statistics summary
                    if (_statistics != null)
                      _StatisticsSummary(statistics: _statistics!),

                    // Free tier limitation banner
                    if (!hasUnlimitedHistory && hiddenCount > 0)
                      _UpgradeBanner(hiddenCount: hiddenCount),

                    // Timeline
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayScans.length,
                          itemBuilder: (context, index) {
                            final scan = displayScans[index];
                            final showDateHeader = index == 0 ||
                                !_isSameDay(
                                  scan.timestamp,
                                  displayScans[index - 1].timestamp,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateHeader)
                                  _DateHeader(date: scan.timestamp),
                                _TimelineEntry(
                                  scan: scan,
                                  onTap: () => _viewScanDetails(scan),
                                  onDelete: () => _deleteScan(scan.id),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SortOption(
              title: 'Newest First',
              value: HistorySortBy.dateNewest,
              currentValue: _sortBy,
              onSelected: _changeSortOrder,
            ),
            _SortOption(
              title: 'Oldest First',
              value: HistorySortBy.dateOldest,
              currentValue: _sortBy,
              onSelected: _changeSortOrder,
            ),
            _SortOption(
              title: 'Highest Quality',
              value: HistorySortBy.qualityHighest,
              currentValue: _sortBy,
              onSelected: _changeSortOrder,
            ),
            _SortOption(
              title: 'Most Insights',
              value: HistorySortBy.insightsMost,
              currentValue: _sortBy,
              onSelected: _changeSortOrder,
            ),
          ],
        ),
      ),
    );
  }

  void _changeSortOrder(HistorySortBy sortBy) {
    setState(() => _sortBy = sortBy);
    Navigator.pop(context);
    _loadHistory();
  }

  void _viewScanDetails(ScanHistoryEntry scan) {
    // Navigate to scan detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for scan ${scan.id}')),
    );
  }

  Future<void> _deleteScan(String id) async {
    try {
      await _historyService.deleteScan(id);
      await _loadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan deleted')),
      );
    } catch (e) {
      _showError('Failed to delete scan: $e');
    }
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all your scan history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearHistory() async {
    try {
      await _historyService.clearAllHistory();
      await _loadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    } catch (e) {
      _showError('Failed to clear history: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showUpgradeDialog() {
    FeatureGate.showProDialog(
      context: context,
      feature: ProFeature.unlimitedHistory,
    );
  }

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }
}

class _StatisticsSummary extends StatelessWidget {
  final HistoryStatistics statistics;

  const _StatisticsSummary({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.camera_alt,
            label: 'Scans',
            value: statistics.totalScans.toString(),
          ),
          _StatItem(
            icon: Icons.insights,
            label: 'Insights',
            value: statistics.totalInsights.toString(),
          ),
          _StatItem(
            icon: Icons.star,
            label: 'Avg Quality',
            value: '${(statistics.averageQuality * 100).toInt()}%',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final scanDate = DateTime(date.year, date.month, date.day);

    if (scanDate == today) {
      return 'Today';
    } else if (scanDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

class _TimelineEntry extends StatelessWidget {
  final ScanHistoryEntry scan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TimelineEntry({
    required this.scan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 80,
                color: Colors.grey.shade300,
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Scan card
          Expanded(
            child: Card(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time and actions
                      Row(
                        children: [
                          Text(
                            _formatTime(scan.timestamp),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Iris preview
                      Row(
                        children: [
                          ClipOval(
                            child: Image.memory(
                              scan.leftIrisImage,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.insights,
                                      size: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${scan.totalInsights} insights',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(scan.metadata.qualityScore * 100).toInt()}% quality',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (scan.hasArtGenerations) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 16,
                                        color: Colors.purple.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${scan.artGenerationIds.length} art ${scan.artGenerationIds.length == 1 ? 'piece' : 'pieces'}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Tags
                      if (scan.metadata.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: scan.metadata.tags
                              .take(3)
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _EmptyHistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Scan History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your scan history will appear here after you complete your first iris scan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String title;
  final HistorySortBy value;
  final HistorySortBy currentValue;
  final Function(HistorySortBy) onSelected;

  const _SortOption({
    required this.title,
    required this.value,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;

    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check) : null,
      selected: isSelected,
      onTap: () => onSelected(value),
    );
  }
}

/// Banner showing upgrade prompt for free users
class _UpgradeBanner extends StatelessWidget {
  final int hiddenCount;

  const _UpgradeBanner({required this.hiddenCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock Full History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have $hiddenCount older scan${hiddenCount == 1 ? '' : 's'} hidden. Upgrade to Pro to view unlimited scan history!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, color: Colors.amber),
        ],
      ),
    );
  }
}
