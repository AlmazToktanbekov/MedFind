import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/clinic_model.dart';

class ClinicsRepository {
  final Dio _dio;

  ClinicsRepository() : _dio = ApiClient().dio;

  Future<List<ClinicModel>> getClinics({String? category}) async {
    final response = await _dio.get('/clinics', queryParameters: {
      'limit': 30,
      ...?category != null ? {'category': category} : null,
    });
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ClinicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClinicModel> getClinicById(int id) async {
    final response = await _dio.get('/clinics/$id');
    return ClinicModel.fromJson(response.data as Map<String, dynamic>);
  }
}
