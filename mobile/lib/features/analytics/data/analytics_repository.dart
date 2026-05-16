import '../../../core/network/api_client.dart';
import 'analytics_models.dart';

class AnalyticsRepository {
  final _dio = ApiClient().dio;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<AnalyticsReport> getClinicReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _dio.get(
      '/analytics/clinic/me',
      queryParameters: {'from': _fmt(from), 'to': _fmt(to)},
    );
    return AnalyticsReport.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AnalyticsReport> getBranchReport({
    required int branchId,
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _dio.get(
      '/analytics/pharmacy/branch/$branchId',
      queryParameters: {'from': _fmt(from), 'to': _fmt(to)},
    );
    return AnalyticsReport.fromJson(res.data as Map<String, dynamic>);
  }
}
