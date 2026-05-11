import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/pharmacy_model.dart';

class PharmaciesRepository {
  final Dio _dio;

  PharmaciesRepository() : _dio = ApiClient().dio;

  // ─── Branches (public) ───────────────────────────────────────────────────

  Future<List<PharmacyBranchModel>> getBranches({int? companyId}) async {
    final params = <String, dynamic>{'limit': 50};
    if (companyId != null) params['company_id'] = companyId;
    final response = await _dio.get('/pharmacy-branches', queryParameters: params);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PharmacyBranchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PharmacyBranchModel>> getNearbyBranches({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final response = await _dio.get('/pharmacy-branches/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PharmacyBranchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PharmacyBranchModel> getBranchById(int id) async {
    final response = await _dio.get('/pharmacy-branches/$id');
    return PharmacyBranchModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Company (public) ────────────────────────────────────────────────────

  Future<PharmacyCompanyModel> getCompanyById(int id) async {
    final response = await _dio.get('/pharmacy-companies/$id');
    return PharmacyCompanyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PharmacyCompanyModel>> getCompanies() async {
    final response = await _dio.get('/pharmacy-companies', queryParameters: {'limit': 50});
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PharmacyCompanyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PharmacyCompanyModel?> getMyCompany() async {
    try {
      final response = await _dio.get('/pharmacy-companies/my');
      if (response.data == null) return null;
      return PharmacyCompanyModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<PharmacyCompanyModel> updateCompany({
    required int companyId,
    String? name,
    String? logoUrl,
    String? coverPhotoUrl,
    String? mainPhone,
    String? website,
    String? description,
  }) async {
    final response = await _dio.put(
      '/pharmacy-companies/$companyId',
      data: {
        'name': ?name,
        'logo_url': ?logoUrl,
        'cover_photo_url': ?coverPhotoUrl,
        'main_phone': ?mainPhone,
        'website': ?website,
        'description': ?description,
      },
    );
    return PharmacyCompanyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PharmacyBranchModel> updateBranch({
    required int branchId,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? workingHours,
    String? mapLink,
    bool? isActive,
  }) async {
    final response = await _dio.put(
      '/pharmacy-branches/$branchId',
      data: {
        'address': ?address,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'phone': ?phone,
        'working_hours': ?workingHours,
        'map_link': ?mapLink,
        'is_active': ?isActive,
      },
    );
    return PharmacyBranchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PharmacyBranchModel> createBranch({
    required int companyId,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? workingHours,
    String? mapLink,
  }) async {
    final response = await _dio.post(
      '/pharmacy-companies/$companyId/branches',
      data: {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (workingHours != null && workingHours.isNotEmpty) 'working_hours': workingHours,
        if (mapLink != null && mapLink.isNotEmpty) 'map_link': mapLink,
      },
    );
    return PharmacyBranchModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Branch photo management ─────────────────────────────────────────────

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

  Future<PharmacyBranchModel> addBranchPhoto(int branchId, String url) async {
    final response = await _dio.post(
      '/pharmacy-branches/$branchId/photos',
      queryParameters: {'url': url},
    );
    return PharmacyBranchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBranchPhoto(int branchId, int photoId) async {
    await _dio.delete('/pharmacy-branches/$branchId/photos/$photoId');
  }
}
