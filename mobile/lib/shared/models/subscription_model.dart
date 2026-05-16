class SubscriptionModel {
  final String ownerType; // "clinic" | "pharmacy"
  final int ownerId;
  final String plan; // "free" | "pro" | "premium"
  final String? period; // "month" | "year" | null
  final bool isTrial;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int? daysLeft;
  final int? doctorLimit; // null = безлимит
  final int? branchLimit;
  final int? currentDoctors;
  final int? currentBranches;

  const SubscriptionModel({
    required this.ownerType,
    required this.ownerId,
    required this.plan,
    required this.isTrial,
    this.period,
    this.startedAt,
    this.expiresAt,
    this.daysLeft,
    this.doctorLimit,
    this.branchLimit,
    this.currentDoctors,
    this.currentBranches,
  });

  bool get isFree => plan == 'free';
  bool get isPro => plan == 'pro';
  bool get isPremium => plan == 'premium';
  bool get hasReports => isPremium;
  bool get hasBadge => isPremium;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      ownerType: json['owner_type'] as String,
      ownerId: json['owner_id'] as int,
      plan: json['plan'] as String,
      period: json['period'] as String?,
      isTrial: json['is_trial'] as bool? ?? false,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      daysLeft: json['days_left'] as int?,
      doctorLimit: json['doctor_limit'] as int?,
      branchLimit: json['branch_limit'] as int?,
      currentDoctors: json['current_doctors'] as int?,
      currentBranches: json['current_branches'] as int?,
    );
  }
}

class PlanInfo {
  final String plan;
  final int priceUsdMonth;
  final int priceUsdYear;
  final int priceKgsMonth;
  final int priceKgsYear;
  final int? doctorLimit;
  final int? branchLimit;
  final bool hasReports;
  final bool hasBadge;

  const PlanInfo({
    required this.plan,
    required this.priceUsdMonth,
    required this.priceUsdYear,
    required this.priceKgsMonth,
    required this.priceKgsYear,
    required this.hasReports,
    required this.hasBadge,
    this.doctorLimit,
    this.branchLimit,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      plan: json['plan'] as String,
      priceUsdMonth: json['price_usd_month'] as int,
      priceUsdYear: json['price_usd_year'] as int,
      priceKgsMonth: json['price_kgs_month'] as int,
      priceKgsYear: json['price_kgs_year'] as int,
      doctorLimit: json['doctor_limit'] as int?,
      branchLimit: json['branch_limit'] as int?,
      hasReports: json['has_reports'] as bool? ?? false,
      hasBadge: json['has_badge'] as bool? ?? false,
    );
  }
}

class PlansResponse {
  final double usdToKgsRate;
  final List<PlanInfo> plans;

  const PlansResponse({required this.usdToKgsRate, required this.plans});

  factory PlansResponse.fromJson(Map<String, dynamic> json) {
    return PlansResponse(
      usdToKgsRate: (json['usd_to_kgs_rate'] as num).toDouble(),
      plans: (json['plans'] as List).map((e) => PlanInfo.fromJson(e)).toList(),
    );
  }
}
