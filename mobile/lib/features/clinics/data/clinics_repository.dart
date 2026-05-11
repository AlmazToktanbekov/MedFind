import 'dart:io';
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

  Future<List<ClinicModel>> getNearbyClinics({
    required double lat,
    required double lon,
    double radiusKm = 5.0,
  }) async {
    final response = await _dio.get('/clinics/nearby', queryParameters: {
      'lat': lat,
      'lon': lon,
      'radius_km': radiusKm,
    });
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ClinicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClinicModel?> getMyClinic() async {
    try {
      final response = await _dio.get('/clinics/my');
      return ClinicModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Doctor management (for clinic owner) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getClinicDoctors(int clinicId) async {
    final response = await _dio.get('/clinics/$clinicId/doctors');
    final list = response.data as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getDoctorRequests(int clinicId) async {
    final response = await _dio.get('/clinics/$clinicId/doctor-requests');
    return response.data as Map<String, dynamic>;
  }

  Future<void> approveDoctor(int clinicId, int doctorId) async {
    await _dio.post('/clinics/$clinicId/approve-doctor/$doctorId');
  }

  Future<void> rejectDoctor(int clinicId, int doctorId) async {
    await _dio.post('/clinics/$clinicId/reject-doctor/$doctorId');
  }

  Future<void> deactivateDoctor(int clinicId, int doctorId) async {
    await _dio.post('/clinics/$clinicId/deactivate-doctor/$doctorId');
  }

  Future<void> activateDoctor(int clinicId, int doctorId) async {
    await _dio.post('/clinics/$clinicId/activate-doctor/$doctorId');
  }

  Future<void> removeDoctor(int clinicId, int doctorId) async {
    await _dio.delete('/clinics/$clinicId/remove-doctor/$doctorId');
  }

  Future<List<Map<String, dynamic>>> getDoctorUpdateRequests(int clinicId) async {
    final response = await _dio.get('/clinics/$clinicId/doctor-update-requests');
    final list = response.data as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getDoctorRaw(int doctorId) async {
    final response = await _dio.get('/doctors/$doctorId');
    return response.data as Map<String, dynamic>;
  }

  Future<void> approveDoctorUpdate(int clinicId, int updateId) async {
    await _dio.post('/clinics/$clinicId/approve-update/$updateId');
  }

  Future<void> rejectDoctorUpdate(int clinicId, int updateId) async {
    await _dio.post('/clinics/$clinicId/reject-update/$updateId');
  }

  // ── Photo management ──────────────────────────────────────────────────

  Future<String> uploadPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: File(filePath).uri.pathSegments.last,
      ),
    });
    final response = await _dio.post('/upload/photo', data: formData);
    return response.data['url'] as String;
  }

  Future<ClinicPhotoModel> addPhoto(int clinicId, String url) async {
    final response = await _dio.post('/clinics/$clinicId/photos',
        data: {'url': url});
    return ClinicPhotoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePhoto(int clinicId, int photoId) async {
    await _dio.delete('/clinics/$clinicId/photos/$photoId');
  }

  Future<void> updateClinic(int clinicId, Map<String, dynamic> body) async {
    await _dio.put('/clinics/$clinicId', data: body);
  }
}
