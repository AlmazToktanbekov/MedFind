import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/doctor_model.dart';

class DoctorsRepository {
  final Dio _dio;

  DoctorsRepository() : _dio = ApiClient().dio;

  Future<List<DoctorModel>> getDoctors({
    String? specialization,
    bool? hasOnline,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get('/doctors', queryParameters: {
      'limit': limit,
      'offset': offset,
      ...?specialization != null ? {'specialization': specialization} : null,
      ...?hasOnline != null ? {'has_online': hasOnline} : null,
    });
    final list = response.data as List<dynamic>;
    return list.map((e) => DoctorModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DoctorModel> getDoctorById(int id) async {
    final response = await _dio.get('/doctors/$id');
    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DoctorModel>> getDoctorsBySymptom(int symptomId) async {
    final response = await _dio.get('/doctors/by-symptom/$symptomId');
    final list = response.data as List<dynamic>;
    return list.map((e) => DoctorModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
