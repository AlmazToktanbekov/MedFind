import '../../../core/network/api_client.dart';
import '../../../shared/models/subscription_model.dart';

class SubscriptionRepository {
  final _dio = ApiClient().dio;

  /// Возвращает текущую подписку владельца (клиники/аптеки) или null если их нет.
  Future<SubscriptionModel?> getMySubscription() async {
    final res = await _dio.get('/subscriptions/me');
    if (res.data == null) return null;
    return SubscriptionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PlansResponse> getPlans() async {
    final res = await _dio.get('/subscriptions/plans');
    return PlansResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
