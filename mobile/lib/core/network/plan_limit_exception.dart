import 'package:dio/dio.dart';

/// Бросается, когда backend вернул HTTP 402 с {code: "plan_limit_reached"}.
class PlanLimitException implements Exception {
  final String limitType;   // "doctors" | "branches"
  final String currentPlan; // "free"
  final int limit;
  final int current;
  final String message;

  const PlanLimitException({
    required this.limitType,
    required this.currentPlan,
    required this.limit,
    required this.current,
    required this.message,
  });

  /// Пробует распознать ошибку Dio как plan limit. Возвращает null если не она.
  static PlanLimitException? tryFromDio(Object error) {
    if (error is! DioException) return null;
    if (error.response?.statusCode != 402) return null;
    final data = error.response?.data;
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is! Map) return null;
    if (detail['code'] != 'plan_limit_reached') return null;
    return PlanLimitException(
      limitType: detail['limit_type'] as String? ?? 'doctors',
      currentPlan: detail['current_plan'] as String? ?? 'free',
      limit: detail['limit'] as int? ?? 0,
      current: detail['current'] as int? ?? 0,
      message: detail['message'] as String? ?? 'Достигнут лимит тарифа',
    );
  }

  @override
  String toString() => 'PlanLimitException($limitType, plan=$currentPlan, limit=$limit)';
}
