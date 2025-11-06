// lib/features/subscription/presentation/providers/subscription_provider.dart
// Riverpod providers for subscription state management

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_status.dart';
import '../../data/services/mock_subscription_service.dart';

/// Subscription service provider
final subscriptionServiceProvider = Provider<MockSubscriptionService>((ref) {
  return MockSubscriptionService();
});

/// Subscription status provider
final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((ref) async* {
  final service = ref.watch(subscriptionServiceProvider);

  // Initial load
  yield await service.getSubscriptionStatus();

  // Poll every 30 seconds for updates
  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    yield await service.getSubscriptionStatus();
  }
});

/// Is pro user provider
final isProUserProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.when(
    data: (status) => status.isPro && status.isActive,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Entitlements provider
final entitlementsProvider = Provider<Entitlements>((ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.when(
    data: (status) => Entitlements.fromSubscriptionStatus(status),
    loading: () => Entitlements.free(),
    error: (_, __) => Entitlements.free(),
  );
});

/// Available products provider
final productsProvider = FutureProvider<List<SubscriptionProduct>>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return await service.getProducts();
});

/// Subscription actions provider
final subscriptionActionsProvider = Provider<SubscriptionActions>((ref) {
  return SubscriptionActions(ref);
});

/// Subscription actions
class SubscriptionActions {
  final Ref _ref;

  SubscriptionActions(this._ref);

  MockSubscriptionService get _service => _ref.read(subscriptionServiceProvider);

  /// Purchase a subscription
  Future<PurchaseResult> purchase(SubscriptionProduct product) async {
    final result = await _service.purchaseSubscription(product);
    if (result.success) {
      // Refresh subscription status
      _ref.invalidate(subscriptionStatusProvider);
    }
    return result;
  }

  /// Restore purchases
  Future<PurchaseResult> restore() async {
    final result = await _service.restorePurchases();
    if (result.success) {
      // Refresh subscription status
      _ref.invalidate(subscriptionStatusProvider);
    }
    return result;
  }

  /// Cancel subscription
  Future<bool> cancel() async {
    final result = await _service.cancelSubscription();
    if (result) {
      // Refresh subscription status
      _ref.invalidate(subscriptionStatusProvider);
    }
    return result;
  }

  /// Start trial (for testing)
  Future<void> startTrial() async {
    await _service.startTrial();
    _ref.invalidate(subscriptionStatusProvider);
  }

  /// Activate pro for testing
  Future<void> activateProForTesting({
    SubscriptionPeriod period = SubscriptionPeriod.monthly,
    int days = 30,
  }) async {
    await _service.activateProForTesting(period: period, days: days);
    _ref.invalidate(subscriptionStatusProvider);
  }

  /// Reset for testing
  Future<void> resetForTesting() async {
    await _service.resetForTesting();
    _ref.invalidate(subscriptionStatusProvider);
  }
}
