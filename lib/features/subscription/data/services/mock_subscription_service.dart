// lib/features/subscription/data/services/mock_subscription_service.dart
// Mock subscription service for testing (replace with RevenueCat in production)

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/subscription_status.dart';

/// Mock subscription service that simulates real behavior
///
/// In production, replace this with a real service that uses:
/// - RevenueCat SDK
/// - Apple StoreKit
/// - Google Play Billing
class MockSubscriptionService {
  static const String _keyIsPro = 'subscription_is_pro';
  static const String _keyProductId = 'subscription_product_id';
  static const String _keyPurchaseDate = 'subscription_purchase_date';
  static const String _keyExpirationDate = 'subscription_expiration_date';
  static const String _keyIsInTrial = 'subscription_is_in_trial';
  static const String _keyTrialEndDate = 'subscription_trial_end_date';

  /// Get current subscription status
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final isPro = prefs.getBool(_keyIsPro) ?? false;
    if (!isPro) {
      return SubscriptionStatus.free();
    }

    final isInTrial = prefs.getBool(_keyIsInTrial) ?? false;
    final productId = prefs.getString(_keyProductId);
    final purchaseDateStr = prefs.getString(_keyPurchaseDate);
    final expirationDateStr = prefs.getString(_keyExpirationDate);
    final trialEndDateStr = prefs.getString(_keyTrialEndDate);

    final purchaseDate = purchaseDateStr != null
        ? DateTime.parse(purchaseDateStr)
        : null;
    final expirationDate = expirationDateStr != null
        ? DateTime.parse(expirationDateStr)
        : null;
    final trialEndDate = trialEndDateStr != null
        ? DateTime.parse(trialEndDateStr)
        : null;

    // Determine period from product ID
    SubscriptionPeriod? period;
    if (productId != null) {
      if (productId.contains('monthly')) {
        period = SubscriptionPeriod.monthly;
      } else if (productId.contains('yearly')) {
        period = SubscriptionPeriod.yearly;
      }
    }

    // Check if subscription has expired
    if (expirationDate != null && DateTime.now().isAfter(expirationDate)) {
      // Expired subscription
      await _clearSubscription();
      return SubscriptionStatus.free();
    }

    if (isInTrial) {
      return SubscriptionStatus.trial(
        trialEndDate: trialEndDate ?? DateTime.now().add(const Duration(days: 7)),
        productId: productId ?? 'iris_pro_monthly',
        period: period ?? SubscriptionPeriod.monthly,
      );
    }

    return SubscriptionStatus.pro(
      expirationDate: expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      purchaseDate: purchaseDate ?? DateTime.now(),
      productId: productId ?? 'iris_pro_monthly',
      period: period ?? SubscriptionPeriod.monthly,
    );
  }

  /// Get available products
  Future<List<SubscriptionProduct>> getProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const SubscriptionProduct(
        id: 'iris_pro_monthly',
        title: 'Iris Pro Monthly',
        description: 'Full access to all pro features',
        price: 4.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.monthly,
        trialDays: 7,
      ),
      const SubscriptionProduct(
        id: 'iris_pro_yearly',
        title: 'Iris Pro Yearly',
        description: 'Full access to all pro features - Best value!',
        price: 39.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.yearly,
        trialDays: 7,
        isPopular: true,
      ),
    ];
  }

  /// Purchase a subscription
  Future<PurchaseResult> purchaseSubscription(SubscriptionProduct product) async {
    try {
      // Simulate purchase flow
      await Future.delayed(const Duration(seconds: 2));

      // Simulate 10% chance of failure for testing
      if (DateTime.now().millisecond % 10 == 0) {
        return PurchaseResult.failure('Payment failed. Please try again.');
      }

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Check if user is eligible for trial
      final hasHadTrial = prefs.getBool('had_trial') ?? false;
      final isInTrial = !hasHadTrial && product.trialDays != null;

      DateTime expirationDate;
      if (isInTrial) {
        // Start trial
        expirationDate = now.add(Duration(days: product.trialDays!));
        await prefs.setBool(_keyIsInTrial, true);
        await prefs.setString(_keyTrialEndDate, expirationDate.toIso8601String());
        await prefs.setBool('had_trial', true);
      } else {
        // Regular subscription
        switch (product.period) {
          case SubscriptionPeriod.monthly:
            expirationDate = now.add(const Duration(days: 30));
            break;
          case SubscriptionPeriod.yearly:
            expirationDate = now.add(const Duration(days: 365));
            break;
        }
        await prefs.setBool(_keyIsInTrial, false);
      }

      await prefs.setBool(_keyIsPro, true);
      await prefs.setString(_keyProductId, product.id);
      await prefs.setString(_keyPurchaseDate, now.toIso8601String());
      await prefs.setString(_keyExpirationDate, expirationDate.toIso8601String());

      final status = await getSubscriptionStatus();
      return PurchaseResult.success(status);
    } catch (e) {
      return PurchaseResult.failure('Purchase failed: $e');
    }
  }

  /// Restore purchases
  Future<PurchaseResult> restorePurchases() async {
    try {
      // Simulate restore
      await Future.delayed(const Duration(seconds: 1));

      // In a real implementation, this would check with Apple/Google
      // For mock, just return current status
      final status = await getSubscriptionStatus();

      if (status.isPro) {
        return PurchaseResult.success(status);
      } else {
        return PurchaseResult.failure('No active subscriptions found');
      }
    } catch (e) {
      return PurchaseResult.failure('Restore failed: $e');
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // In real implementation, would call Apple/Google APIs
      // For mock, just clear local data
      await _clearSubscription();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has active pro subscription
  Future<bool> isProUser() async {
    final status = await getSubscriptionStatus();
    return status.isPro && status.isActive;
  }

  /// Get entitlements based on subscription
  Future<Entitlements> getEntitlements() async {
    final status = await getSubscriptionStatus();
    return Entitlements.fromSubscriptionStatus(status);
  }

  /// Start a trial (for testing)
  Future<void> startTrial() async {
    final product = SubscriptionProduct(
      id: 'iris_pro_monthly',
      title: 'Iris Pro Monthly',
      description: 'Trial subscription',
      price: 4.99,
      currencyCode: 'USD',
      period: SubscriptionPeriod.monthly,
      trialDays: 7,
    );

    await purchaseSubscription(product);
  }

  /// Activate pro (for testing - bypass purchase)
  Future<void> activateProForTesting({
    SubscriptionPeriod period = SubscriptionPeriod.monthly,
    int days = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final expirationDate = now.add(Duration(days: days));

    await prefs.setBool(_keyIsPro, true);
    await prefs.setString(_keyProductId,
      period == SubscriptionPeriod.monthly ? 'iris_pro_monthly' : 'iris_pro_yearly'
    );
    await prefs.setString(_keyPurchaseDate, now.toIso8601String());
    await prefs.setString(_keyExpirationDate, expirationDate.toIso8601String());
    await prefs.setBool(_keyIsInTrial, false);
  }

  /// Clear subscription (for testing)
  Future<void> _clearSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsPro);
    await prefs.remove(_keyProductId);
    await prefs.remove(_keyPurchaseDate);
    await prefs.remove(_keyExpirationDate);
    await prefs.remove(_keyIsInTrial);
    await prefs.remove(_keyTrialEndDate);
  }

  /// Reset all subscription data (for testing)
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearSubscription();
    await prefs.remove('had_trial');
  }
}

/// TODO: In production, replace MockSubscriptionService with:
///
/// ```dart
/// import 'package:purchases_flutter/purchases_flutter.dart';
///
/// class RevenueCatService {
///   Future<void> initialize(String apiKey) async {
///     await Purchases.configure(PurchasesConfiguration(apiKey));
///   }
///
///   Future<SubscriptionStatus> getSubscriptionStatus() async {
///     final customerInfo = await Purchases.getCustomerInfo();
///     final entitlements = customerInfo.entitlements.all['pro'];
///     // Convert to SubscriptionStatus
///   }
///
///   Future<List<SubscriptionProduct>> getProducts() async {
///     final offerings = await Purchases.getOfferings();
///     // Convert to SubscriptionProduct list
///   }
///
///   Future<PurchaseResult> purchaseSubscription(String productId) async {
///     final result = await Purchases.purchaseProduct(productId);
///     // Convert to PurchaseResult
///   }
///
///   Future<PurchaseResult> restorePurchases() async {
///     final customerInfo = await Purchases.restorePurchases();
///     // Convert to PurchaseResult
///   }
/// }
/// ```
