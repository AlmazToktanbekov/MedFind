import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/doctor_model.dart';
import '../../../shared/models/clinic_model.dart';
import '../../../shared/models/pharmacy_model.dart';

class SearchResultsModel {
  final List<DoctorModel> doctors;
  final List<ClinicModel> clinics;
  final List<PharmacyCompanyModel> pharmacies;
  final List<String> specializations;

  const SearchResultsModel({
    this.doctors = const [],
    this.clinics = const [],
    this.pharmacies = const [],
    this.specializations = const [],
  });

  bool get isEmpty => doctors.isEmpty && clinics.isEmpty && pharmacies.isEmpty;

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) {
    return SearchResultsModel(
      doctors: (json['doctors'] as List<dynamic>? ?? [])
          .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      clinics: (json['clinics'] as List<dynamic>? ?? [])
          .map((e) => ClinicModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pharmacies: (json['pharmacies'] as List<dynamic>? ?? [])
          .map((e) => PharmacyCompanyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      specializations: (json['specializations'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class SearchRepository {
  final Dio _dio;

  SearchRepository() : _dio = ApiClient().dio;

  Future<SearchResultsModel> search(String query) async {
    final response = await _dio.get('/search', queryParameters: {'q': query});
    return SearchResultsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> getSpecializations() async {
    final response = await _dio.get('/search/specializations');
    final list = response.data as List<dynamic>;
    return list.map((e) => e as String).toList();
  }

  Future<List<String>> getCategories() async {
    final response = await _dio.get('/search/categories');
    final list = response.data as List<dynamic>;
    return list.map((e) => e as String).toList();
  }
}
