// lib/core/utils/feature_gate.dart
// Feature gating utilities for free vs pro features

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscription/domain/entities/subscription_status.dart';
import '../../features/subscription/presentation/providers/subscription_provider.dart';

/// Feature gating utility for checking pro status and prompting upgrades
class FeatureGate {
  /// Check if user has pro access
  static bool isPro(WidgetRef ref) {
    final statusAsync = ref.read(subscriptionStatusProvider);
    return statusAsync.when(
      data: (status) => status.isPro && status.isActive,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// Get current subscription status
  static SubscriptionStatus? getStatus(WidgetRef ref) {
    final statusAsync = ref.read(subscriptionStatusProvider);
    return statusAsync.when(
      data: (status) => status,
      loading: () => null,
      error: (_, __) => null,
    );
  }

  /// Check if a specific feature is unlocked
  static bool isFeatureUnlocked(WidgetRef ref, ProFeature feature) {
    if (!isPro(ref)) return false;

    final status = getStatus(ref);
    if (status == null) return false;

    final entitlements = Entitlements.fromSubscriptionStatus(status);

    switch (feature) {
      case ProFeature.proArtStyles:
        return entitlements.hasProArtStyles;
      case ProFeature.unlimitedHistory:
        return entitlements.hasUnlimitedHistory;
      case ProFeature.export4K:
        return entitlements.has4KExports;
      case ProFeature.advancedAnalytics:
        return entitlements.hasAdvancedAnalytics;
      case ProFeature.allExportFormats:
        return entitlements.hasAllExportFormats;
      case ProFeature.noWatermark:
        return entitlements.hasNoWatermark;
      case ProFeature.prioritySupport:
        return entitlements.hasPrioritySupport;
      case ProFeature.advancedSearch:
        return entitlements.hasAdvancedSearch;
    }
  }

  /// Require pro access for a feature, show paywall if not pro
  /// Returns true if user has access, false if paywall was shown
  static Future<bool> requiresPro({
    required BuildContext context,
    required WidgetRef ref,
    required ProFeature feature,
    String? customMessage,
  }) async {
    if (isFeatureUnlocked(ref, feature)) {
      return true;
    }

    // Show paywall
    final result = await showProDialog(
      context: context,
      feature: feature,
      customMessage: customMessage,
    );

    return result == true;
  }

  /// Show upgrade dialog for a locked feature
  static Future<bool?> showProDialog({
    required BuildContext context,
    required ProFeature feature,
    String? customMessage,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _ProFeatureDialog(
        feature: feature,
        customMessage: customMessage,
      ),
    );
  }

  /// Show a simple locked snackbar
  static void showLockedSnackbar(BuildContext context, ProFeature feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${feature.displayName} is a Pro feature'),
        action: SnackBarAction(
          label: 'Upgrade',
          onPressed: () {
            Navigator.pushNamed(context, '/paywall', arguments: feature.name);
          },
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Get free tier limitations
  static const int maxFreeHistoryScans = 10;
  static const int maxFreeArtGenerations = 3;
  static const List<String> freeExportFormats = ['json'];
}

/// Pro features enum
enum ProFeature {
  proArtStyles,
  unlimitedHistory,
  export4K,
  advancedAnalytics,
  allExportFormats,
  noWatermark,
  prioritySupport,
  advancedSearch;

  String get displayName {
    switch (this) {
      case ProFeature.proArtStyles:
        return 'Pro Art Styles';
      case ProFeature.unlimitedHistory:
        return 'Unlimited History';
      case ProFeature.export4K:
        return '4K Exports';
      case ProFeature.advancedAnalytics:
        return 'Advanced Analytics';
      case ProFeature.allExportFormats:
        return 'All Export Formats';
      case ProFeature.noWatermark:
        return 'No Watermark';
      case ProFeature.prioritySupport:
        return 'Priority Support';
      case ProFeature.advancedSearch:
        return 'Advanced Search';
    }
  }

  String get description {
    switch (this) {
      case ProFeature.proArtStyles:
        return 'Access all 12 art styles including premium watercolor, oil painting, and surreal effects.';
      case ProFeature.unlimitedHistory:
        return 'Save unlimited scans and track your wellness journey over time.';
      case ProFeature.export4K:
        return 'Export your iris art in ultra high-resolution 4K quality.';
      case ProFeature.advancedAnalytics:
        return 'View detailed wellness trends, charts, and insights over time.';
      case ProFeature.allExportFormats:
        return 'Export your scan data in JSON, CSV, and Text formats.';
      case ProFeature.noWatermark:
        return 'Remove watermarks from all your exports and art generations.';
      case ProFeature.prioritySupport:
        return 'Get priority customer support and faster response times.';
      case ProFeature.advancedSearch:
        return 'Search your scan history with advanced filters and criteria.';
    }
  }

  IconData get icon {
    switch (this) {
      case ProFeature.proArtStyles:
        return Icons.auto_awesome;
      case ProFeature.unlimitedHistory:
        return Icons.history;
      case ProFeature.export4K:
        return Icons.high_quality;
      case ProFeature.advancedAnalytics:
        return Icons.analytics;
      case ProFeature.allExportFormats:
        return Icons.file_download;
      case ProFeature.noWatermark:
        return Icons.no_photography;
      case ProFeature.prioritySupport:
        return Icons.support_agent;
      case ProFeature.advancedSearch:
        return Icons.search;
    }
  }
}

/// Dialog shown when user tries to access a pro feature
class _ProFeatureDialog extends StatelessWidget {
  final ProFeature feature;
  final String? customMessage;

  const _ProFeatureDialog({
    required this.feature,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Upgrade to Pro',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customMessage != null) ...[
            Text(
              customMessage!,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  feature.icon,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock this feature and more with Iris Pro!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, false);
            Navigator.pushNamed(
              context,
              '/paywall',
              arguments: feature.name,
            );
          },
          icon: const Icon(Icons.star),
          label: const Text('Upgrade Now'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget that shows a pro badge on locked features
class ProBadge extends StatelessWidget {
  final bool isLocked;
  final ProBadgeStyle style;

  const ProBadge({
    super.key,
    this.isLocked = true,
    this.style = ProBadgeStyle.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return const SizedBox.shrink();

    switch (style) {
      case ProBadgeStyle.compact:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 12, color: Colors.black87),
              SizedBox(width: 4),
              Text(
                'PRO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );

      case ProBadgeStyle.large:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'PRO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

      case ProBadgeStyle.overlay:
        return Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: Colors.black87),
                SizedBox(width: 4),
                Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

enum ProBadgeStyle {
  compact,
  large,
  overlay,
}

/// Widget that applies a lock overlay to locked features
class LockedFeatureOverlay extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final VoidCallback? onTap;

  const LockedFeatureOverlay({
    super.key,
    required this.child,
    this.isLocked = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        // Dimmed content
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.grey.withOpacity(0.5),
            BlendMode.saturation,
          ),
          child: Opacity(
            opacity: 0.6,
            child: child,
          ),
        ),

        // Lock overlay
        Positioned.fill(
          child: Material(
            color: Colors.black.withOpacity(0.1),
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pro Feature',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to upgrade',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
