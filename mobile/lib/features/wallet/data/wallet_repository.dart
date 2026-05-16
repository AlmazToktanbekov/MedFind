import '../../../core/network/api_client.dart';
import '../../../shared/models/wallet_model.dart';

class WalletRepository {
  final _dio = ApiClient().dio;

  Future<WalletModel> getMyWallet() async {
    final res = await _dio.get('/wallet/me');
    return WalletModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<WalletTransactionModel>> getTransactions({int limit = 50}) async {
    final res = await _dio.get(
      '/wallet/me/transactions',
      queryParameters: {'limit': limit, 'offset': 0},
    );
    return (res.data as List)
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentInfo> getPaymentInfo() async {
    final res = await _dio.get('/wallet/me/payment-info');
    return PaymentInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WalletTransactionModel> createTopupRequest({
    required int amountUsd,
    String? comment,
  }) async {
    final res = await _dio.post(
      '/wallet/me/topup-request',
      data: {
        'amount_usd': amountUsd,
        'comment': ?comment,
      },
    );
    return WalletTransactionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WalletTransactionModel> purchaseSubscription({
    required String plan,    // "pro" | "premium"
    required String period,  // "month" | "year"
  }) async {
    final res = await _dio.post(
      '/wallet/me/purchase',
      data: {'plan': plan, 'period': period},
    );
    return WalletTransactionModel.fromJson(res.data as Map<String, dynamic>);
  }
}
