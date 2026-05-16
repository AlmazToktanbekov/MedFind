class WalletModel {
  final String ownerType; // "clinic" | "pharmacy"
  final int ownerId;
  final double balanceUsd;
  final double balanceKgs;
  final DateTime updatedAt;

  const WalletModel({
    required this.ownerType,
    required this.ownerId,
    required this.balanceUsd,
    required this.balanceKgs,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      ownerType: json['owner_type'] as String,
      ownerId: json['owner_id'] as int,
      balanceUsd: (json['balance_usd'] as num).toDouble(),
      balanceKgs: (json['balance_kgs'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class WalletTransactionModel {
  final int id;
  final String type;   // "topup" | "purchase" | "refund" | "credit"
  final String status; // "pending" | "success" | "cancelled"
  final double amountUsd;
  final double? balanceAfterUsd;
  final String? paymentCode;
  final String? comment;
  final int? relatedSubscriptionId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amountUsd,
    required this.createdAt,
    this.balanceAfterUsd,
    this.paymentCode,
    this.comment,
    this.relatedSubscriptionId,
    this.completedAt,
  });

  /// Знак для отображения: пополнения/возвраты — плюс, покупки — минус.
  bool get isCredit => type == 'topup' || type == 'refund' || type == 'credit';

  /// Сумма со знаком (для display, без учёта статуса).
  double get signedAmountUsd => isCredit ? amountUsd : -amountUsd;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int,
      type: json['type'] as String,
      status: json['status'] as String,
      amountUsd: (json['amount_usd'] as num).toDouble(),
      balanceAfterUsd: (json['balance_after_usd'] as num?)?.toDouble(),
      paymentCode: json['payment_code'] as String?,
      comment: json['comment'] as String?,
      relatedSubscriptionId: json['related_subscription_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

class PaymentInfo {
  final String companyName;
  final String inn;
  final String bankName;
  final String bankAccount;
  final String bankBik;
  final String supportPhone;
  final int minAmountUsd;
  final int maxAmountUsd;
  final double usdToKgsRate;

  const PaymentInfo({
    required this.companyName,
    required this.inn,
    required this.bankName,
    required this.bankAccount,
    required this.bankBik,
    required this.supportPhone,
    required this.minAmountUsd,
    required this.maxAmountUsd,
    required this.usdToKgsRate,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      companyName: json['company_name'] as String,
      inn: json['inn'] as String,
      bankName: json['bank_name'] as String,
      bankAccount: json['bank_account'] as String,
      bankBik: json['bank_bik'] as String,
      supportPhone: json['support_phone'] as String,
      minAmountUsd: json['min_amount_usd'] as int,
      maxAmountUsd: json['max_amount_usd'] as int,
      usdToKgsRate: (json['usd_to_kgs_rate'] as num).toDouble(),
    );
  }
}
