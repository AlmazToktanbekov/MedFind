import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/pharmacy_model.dart';

class PharmaciesRepository {
  final Dio _dio;

  PharmaciesRepository() : _dio = ApiClient().dio;

  Future<List<PharmacyModel>> getPharmacies() async {
    final response = await _dio.get('/pharmacies', queryParameters: {'limit': 30});
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PharmacyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PharmacyModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final response = await _dio.get('/pharmacies/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PharmacyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PharmacyModel> getPharmacyById(int id) async {
    final response = await _dio.get('/pharmacies/$id');
    return PharmacyModel.fromJson(response.data as Map<String, dynamic>);
  }
}
