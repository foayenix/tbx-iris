// lib/features/subscription/presentation/screens/subscription_management_screen.dart
// Screen for managing active subscription

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_status.dart';
import '../providers/subscription_provider.dart';

/// Subscription management screen for pro users
class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: statusAsync.when(
        data: (status) => _buildContent(context, ref, status),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading subscription: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SubscriptionStatus status,
  ) {
    if (!status.isPro) {
      return _buildFreeState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status card
          _StatusCard(status: status),

          const SizedBox(height: 24),

          // Trial warning (if applicable)
          if (status.isInTrial && status.isTrialEndingSoon)
            _TrialWarningCard(status: status),

          if (status.isInTrial && status.isTrialEndingSoon)
            const SizedBox(height: 24),

          // Plan details
          _PlanDetailsCard(status: status),

          const SizedBox(height: 24),

          // Billing info
          if (!status.isInTrial) _BillingInfoCard(status: status),

          if (!status.isInTrial) const SizedBox(height: 24),

          // Actions
          _ActionsSection(status: status),

          const SizedBox(height: 24),

          // Debug actions (remove in production)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            _DebugSection(ref: ref),
        ],
      ),
    );
  }

  Widget _buildFreeState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re on the Free Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade to Iris Pro to unlock all premium features!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to paywall
                Navigator.pushNamed(context, '/paywall');
              },
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Pro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SubscriptionStatus status;

  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.star,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              status.isInTrial ? 'Free Trial Active' : 'Iris Pro',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status.isInTrial
                  ? '${status.trialDaysRemaining} days remaining'
                  : 'Active Subscription',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrialWarningCard extends StatelessWidget {
  final SubscriptionStatus status;

  const _TrialWarningCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trial Ending Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your trial ends in ${status.trialDaysRemaining} days. Your subscription will automatically continue.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanDetailsCard extends StatelessWidget {
  final SubscriptionStatus status;

  const _PlanDetailsCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Plan Type',
              value: status.period?.displayName ?? 'N/A',
            ),
            _DetailRow(
              label: 'Status',
              value: status.isInTrial ? 'Trial' : 'Active',
            ),
            if (status.expirationDate != null)
              _DetailRow(
                label: status.isInTrial ? 'Trial Ends' : 'Renews',
                value: _formatDate(status.expirationDate!),
              ),
            if (status.purchaseDate != null)
              _DetailRow(
                label: 'Started',
                value: _formatDate(status.purchaseDate!),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingInfoCard extends StatelessWidget {
  final SubscriptionStatus status;

  const _BillingInfoCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final price = status.period == SubscriptionPeriod.monthly
        ? '\$4.99'
        : '\$39.99';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Amount',
              value: price,
            ),
            _DetailRow(
              label: 'Billing Cycle',
              value: status.period?.displayName ?? 'N/A',
            ),
            _DetailRow(
              label: 'Auto-Renew',
              value: status.willRenew ? 'On' : 'Off',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsSection extends ConsumerWidget {
  final SubscriptionStatus status;

  const _ActionsSection({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _handleRestore(context, ref),
          icon: const Icon(Icons.refresh),
          label: const Text('Restore Purchases'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showCancelDialog(context, ref),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Subscription'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(subscriptionActionsProvider);
    final result = await actions.restore();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Purchases restored!'
                : result.errorMessage ?? 'Restore failed',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Are you sure you want to cancel? You\'ll lose access to all Pro features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final actions = ref.read(subscriptionActionsProvider);
              final success = await actions.cancel();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Subscription cancelled'
                          : 'Failed to cancel subscription',
                    ),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}

class _DebugSection extends StatelessWidget {
  final WidgetRef ref;

  const _DebugSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Debug Actions (Development Only)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final actions = ref.read(subscriptionActionsProvider);
                await actions.activateProForTesting(days: 30);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activated Pro for 30 days')),
                  );
                }
              },
              child: const Text('Activate Pro (30 days)'),
            ),
            TextButton(
              onPressed: () async {
                final actions = ref.read(subscriptionActionsProvider);
                await actions.startTrial();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Started 7-day trial')),
                  );
                }
              },
              child: const Text('Start Trial (7 days)'),
            ),
            TextButton(
              onPressed: () async {
                final actions = ref.read(subscriptionActionsProvider);
                await actions.resetForTesting();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset to Free')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset to Free'),
            ),
          ],
        ),
      ),
    );
  }
}
