import '../../core/constants/app_constants.dart';

class DoctorContactModel {
  final int id;
  final String type; // phone | whatsapp | telegram | instagram
  final String value;

  const DoctorContactModel({
    required this.id,
    required this.type,
    required this.value,
  });

  factory DoctorContactModel.fromJson(Map<String, dynamic> json) {
    return DoctorContactModel(
      id: json['id'] as int,
      type: json['type'] as String,
      value: json['value'] as String,
    );
  }
}

class DoctorModel {
  final int id;
  final String fullName;
  final String specialization;
  final String? bio;
  final String? education;
  final String? consultationLanguage;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final int? experienceYears;
  final int? clinicId;
  final String? clinicName;
  final double rating;
  final int reviewCount;
  final bool hasOnline;
  final bool hasOffline;
  final double? onlinePrice;
  final double? offlinePrice;
  final int? onlineDurationMin;
  final int? offlineDurationMin;
  final String status;
  final List<DoctorContactModel> contacts;

  const DoctorModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    this.bio,
    this.education,
    this.consultationLanguage,
    this.photoUrl,
    this.coverPhotoUrl,
    this.experienceYears,
    this.clinicId,
    this.clinicName,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.hasOnline = false,
    this.hasOffline = true,
    this.onlinePrice,
    this.offlinePrice,
    this.onlineDurationMin,
    this.offlineDurationMin,
    this.status = 'active',
    this.contacts = const [],
  });

  String? get whatsapp => _contactValue('whatsapp');
  String? get telegram => _contactValue('telegram');
  String? get phone => _contactValue('phone');
  String? get instagram => _contactValue('instagram');

  String? _contactValue(String type) {
    try {
      return contacts.firstWhere((c) => c.type == type).value;
    } catch (_) {
      return null;
    }
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final contactsJson = json['contacts'] as List<dynamic>? ?? [];
    return DoctorModel(
      id: json['id'] as int,
      fullName: json['full_name_ru'] as String? ?? '',
      specialization: json['specialization_ru'] as String? ?? '',
      bio: json['bio_ru'] as String?,
      education: json['education'] as String?,
      consultationLanguage: json['consultation_language'] as String?,
      photoUrl: AppConstants.fixUrlOrNull(json['photo_url'] as String?),
      coverPhotoUrl: AppConstants.fixUrlOrNull(json['cover_photo_url'] as String?),
      experienceYears: json['experience_years'] as int?,
      clinicId: json['clinic_id'] as int?,
      clinicName: json['clinic_name'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviews_count'] as int? ?? 0,
      hasOnline: json['has_online'] as bool? ?? false,
      hasOffline: json['has_offline'] as bool? ?? true,
      onlinePrice: (json['online_price'] as num?)?.toDouble(),
      offlinePrice: (json['offline_price'] as num?)?.toDouble(),
      onlineDurationMin: json['online_duration_min'] as int?,
      offlineDurationMin: json['offline_duration_min'] as int?,
      status: json['status'] as String? ?? 'active',
      contacts:
          contactsJson.map((c) => DoctorContactModel.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}
