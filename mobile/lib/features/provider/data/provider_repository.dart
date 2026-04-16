import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';

class ProviderRepository {
  final Dio _dio;
  final ImagePicker _picker;

  ProviderRepository()
      : _dio = ApiClient().dio,
        _picker = ImagePicker();

  /// Открывает галерею и возвращает путь к выбранному фото (null если отменено)
  Future<String?> pickImagePath() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    return xFile?.path;
  }

  /// Загружает фото на сервер и возвращает URL
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

  // ─── Doctor ────────────────────────────────────────────────────────────

  Future<int> createDoctor(Map<String, dynamic> body) async {
    final response = await _dio.post('/doctors', data: body);
    return response.data['id'] as int;
  }

  Future<int> updateDoctor(int doctorId, Map<String, dynamic> body) async {
    final response = await _dio.put('/doctors/$doctorId', data: body);
    return response.data['id'] as int;
  }

  Future<Map<String, dynamic>?> getMyDoctor() async {
    try {
      final response = await _dio.get('/doctors/my');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── Clinic ────────────────────────────────────────────────────────────

  Future<int> createClinic(Map<String, dynamic> body) async {
    final response = await _dio.post('/clinics', data: body);
    return response.data['id'] as int;
  }

  Future<int> updateClinic(int clinicId, Map<String, dynamic> body) async {
    final response = await _dio.put('/clinics/$clinicId', data: body);
    return response.data['id'] as int;
  }

  Future<Map<String, dynamic>?> getMyClinic() async {
    try {
      final response = await _dio.get('/clinics/my');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── Pharmacy ──────────────────────────────────────────────────────────

  Future<int> createPharmacy(Map<String, dynamic> body) async {
    final response = await _dio.post('/pharmacies', data: body);
    return response.data['id'] as int;
  }

  Future<int> updatePharmacy(int pharmacyId, Map<String, dynamic> body) async {
    final response = await _dio.put('/pharmacies/$pharmacyId', data: body);
    return response.data['id'] as int;
  }

  Future<Map<String, dynamic>?> getMyPharmacy() async {
    try {
      final response = await _dio.get('/pharmacies/my');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
