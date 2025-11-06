// lib/features/subscription/domain/entities/subscription_status.dart
// Domain entities for subscription management

/// User's subscription status
class SubscriptionStatus {
  final bool isPro;
  final SubscriptionTier tier;
  final DateTime? expirationDate;
  final DateTime? purchaseDate;
  final bool isInTrial;
  final DateTime? trialEndDate;
  final bool willRenew;
  final String? productId;
  final SubscriptionPeriod? period;

  const SubscriptionStatus({
    required this.isPro,
    required this.tier,
    this.expirationDate,
    this.purchaseDate,
    this.isInTrial = false,
    this.trialEndDate,
    this.willRenew = true,
    this.productId,
    this.period,
  });

  /// Free user
  factory SubscriptionStatus.free() {
    return const SubscriptionStatus(
      isPro: false,
      tier: SubscriptionTier.free,
    );
  }

  /// Pro user with trial
  factory SubscriptionStatus.trial({
    required DateTime trialEndDate,
    required String productId,
    required SubscriptionPeriod period,
  }) {
    return SubscriptionStatus(
      isPro: true,
      tier: SubscriptionTier.pro,
      isInTrial: true,
      trialEndDate: trialEndDate,
      expirationDate: trialEndDate,
      productId: productId,
      period: period,
      willRenew: true,
    );
  }

  /// Pro user with active subscription
  factory SubscriptionStatus.pro({
    required DateTime expirationDate,
    required DateTime purchaseDate,
    required String productId,
    required SubscriptionPeriod period,
    bool willRenew = true,
  }) {
    return SubscriptionStatus(
      isPro: true,
      tier: SubscriptionTier.pro,
      expirationDate: expirationDate,
      purchaseDate: purchaseDate,
      productId: productId,
      period: period,
      willRenew: willRenew,
    );
  }

  /// Check if subscription is active
  bool get isActive {
    if (!isPro) return false;
    if (expirationDate == null) return false;
    return DateTime.now().isBefore(expirationDate!);
  }

  /// Get days remaining
  int? get daysRemaining {
    if (expirationDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expirationDate!)) return 0;
    return expirationDate!.difference(now).inDays;
  }

  /// Get trial days remaining
  int? get trialDaysRemaining {
    if (!isInTrial || trialEndDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(trialEndDate!)) return 0;
    return trialEndDate!.difference(now).inDays;
  }

  /// Check if trial is ending soon (within 2 days)
  bool get isTrialEndingSoon {
    if (!isInTrial) return false;
    final remaining = trialDaysRemaining;
    return remaining != null && remaining <= 2;
  }

  /// Copy with updated fields
  SubscriptionStatus copyWith({
    bool? isPro,
    SubscriptionTier? tier,
    DateTime? expirationDate,
    DateTime? purchaseDate,
    bool? isInTrial,
    DateTime? trialEndDate,
    bool? willRenew,
    String? productId,
    SubscriptionPeriod? period,
  }) {
    return SubscriptionStatus(
      isPro: isPro ?? this.isPro,
      tier: tier ?? this.tier,
      expirationDate: expirationDate ?? this.expirationDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isInTrial: isInTrial ?? this.isInTrial,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      willRenew: willRenew ?? this.willRenew,
      productId: productId ?? this.productId,
      period: period ?? this.period,
    );
  }
}

/// Subscription tier
enum SubscriptionTier {
  free,
  pro;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }
}

/// Subscription period
enum SubscriptionPeriod {
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case SubscriptionPeriod.monthly:
        return 'Monthly';
      case SubscriptionPeriod.yearly:
        return 'Yearly';
    }
  }

  String get shortName {
    switch (this) {
      case SubscriptionPeriod.monthly:
        return 'month';
      case SubscriptionPeriod.yearly:
        return 'year';
    }
  }
}

/// Subscription product
class SubscriptionProduct {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currencyCode;
  final SubscriptionPeriod period;
  final int? trialDays;
  final String? introPrice;
  final bool isPopular;

  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.period,
    this.trialDays,
    this.introPrice,
    this.isPopular = false,
  });

  String get priceString => '$currencyCode $price';

  String get pricePerPeriod {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return '$priceString/month';
      case SubscriptionPeriod.yearly:
        return '$priceString/year';
    }
  }

  String get pricePerMonth {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return priceString;
      case SubscriptionPeriod.yearly:
        final monthly = price / 12;
        return '$currencyCode ${monthly.toStringAsFixed(2)}';
    }
  }

  double get savings {
    if (period != SubscriptionPeriod.yearly) return 0;
    const monthlyPrice = 4.99; // Reference monthly price
    final yearlyMonthly = price / 12;
    return ((monthlyPrice - yearlyMonthly) / monthlyPrice) * 100;
  }

  String get savingsText {
    if (period != SubscriptionPeriod.yearly) return '';
    return 'Save ${savings.toInt()}%';
  }
}

/// Purchase result
class PurchaseResult {
  final bool success;
  final SubscriptionStatus? subscriptionStatus;
  final String? errorMessage;

  const PurchaseResult({
    required this.success,
    this.subscriptionStatus,
    this.errorMessage,
  });

  factory PurchaseResult.success(SubscriptionStatus status) {
    return PurchaseResult(
      success: true,
      subscriptionStatus: status,
    );
  }

  factory PurchaseResult.failure(String error) {
    return PurchaseResult(
      success: false,
      errorMessage: error,
    );
  }

  factory PurchaseResult.cancelled() {
    return const PurchaseResult(
      success: false,
      errorMessage: 'Purchase cancelled by user',
    );
  }
}

/// Entitlements (features unlocked by subscription)
class Entitlements {
  final bool hasProArtStyles;
  final bool hasUnlimitedHistory;
  final bool has4KExports;
  final bool hasAdvancedAnalytics;
  final bool hasAllExportFormats;
  final bool hasNoWatermark;
  final bool hasPrioritySupport;
  final bool hasAdvancedSearch;

  const Entitlements({
    required this.hasProArtStyles,
    required this.hasUnlimitedHistory,
    required this.has4KExports,
    required this.hasAdvancedAnalytics,
    required this.hasAllExportFormats,
    required this.hasNoWatermark,
    required this.hasPrioritySupport,
    required this.hasAdvancedSearch,
  });

  /// Free user entitlements
  factory Entitlements.free() {
    return const Entitlements(
      hasProArtStyles: false,
      hasUnlimitedHistory: false,
      has4KExports: false,
      hasAdvancedAnalytics: false,
      hasAllExportFormats: false,
      hasNoWatermark: false,
      hasPrioritySupport: false,
      hasAdvancedSearch: false,
    );
  }

  /// Pro user entitlements
  factory Entitlements.pro() {
    return const Entitlements(
      hasProArtStyles: true,
      hasUnlimitedHistory: true,
      has4KExports: true,
      hasAdvancedAnalytics: true,
      hasAllExportFormats: true,
      hasNoWatermark: true,
      hasPrioritySupport: true,
      hasAdvancedSearch: true,
    );
  }

  factory Entitlements.fromSubscriptionStatus(SubscriptionStatus status) {
    if (status.isPro && status.isActive) {
      return Entitlements.pro();
    }
    return Entitlements.free();
  }
}
