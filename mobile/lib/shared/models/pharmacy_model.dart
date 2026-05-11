import '../../core/constants/app_constants.dart';

class PharmacyBranchPhotoModel {
  final int id;
  final String url;
  final int order;

  const PharmacyBranchPhotoModel({
    required this.id,
    required this.url,
    required this.order,
  });

  factory PharmacyBranchPhotoModel.fromJson(Map<String, dynamic> json) {
    return PharmacyBranchPhotoModel(
      id: json['id'] as int,
      url: AppConstants.fixUrl(json['url'] as String),
      order: json['order'] as int? ?? 0,
    );
  }
}

class PharmacyBranchModel {
  final int id;
  final int companyId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? workingHours;
  final bool isActive;
  final double rating;
  final int reviewsCount;
  final List<PharmacyBranchPhotoModel> photos;
  final double? distanceKm;

  // Поля компании (подставляются сервером)
  final String? companyName;
  final String? companyLogoUrl;
  final String? companyWhatsapp;
  final String? companyInstagram;
  final String? companyWebsite;
  final String? companyMainPhone;

  const PharmacyBranchModel({
    required this.id,
    required this.companyId,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.workingHours,
    this.isActive = true,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.photos = const [],
    this.distanceKm,
    this.companyName,
    this.companyLogoUrl,
    this.companyWhatsapp,
    this.companyInstagram,
    this.companyWebsite,
    this.companyMainPhone,
  });

  factory PharmacyBranchModel.fromJson(Map<String, dynamic> json) {
    final photosJson = json['photos'] as List<dynamic>? ?? [];
    return PharmacyBranchModel(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      workingHours: json['working_hours'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      photos: photosJson
          .map((p) => PharmacyBranchPhotoModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      companyName: json['company_name'] as String?,
      companyLogoUrl: AppConstants.fixUrlOrNull(json['company_logo_url'] as String?),
      companyWhatsapp: json['company_whatsapp'] as String?,
      companyInstagram: json['company_instagram'] as String?,
      companyWebsite: json['company_website'] as String?,
      companyMainPhone: json['company_main_phone'] as String?,
    );
  }
}

class PharmacyCompanyModel {
  final int id;
  final String name;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final String? mainPhone;
  final String? website;
  final String? description;
  final String? whatsapp;
  final String? instagram;
  final List<PharmacyBranchModel> branches;

  const PharmacyCompanyModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverPhotoUrl,
    this.mainPhone,
    this.website,
    this.description,
    this.whatsapp,
    this.instagram,
    this.branches = const [],
  });

  factory PharmacyCompanyModel.fromJson(Map<String, dynamic> json) {
    final branchesJson = json['branches'] as List<dynamic>? ?? [];
    return PharmacyCompanyModel(
      id: json['id'] as int,
      name: json['name'] as String,
      logoUrl: AppConstants.fixUrlOrNull(json['logo_url'] as String?),
      coverPhotoUrl: AppConstants.fixUrlOrNull(json['cover_photo_url'] as String?),
      mainPhone: json['main_phone'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      whatsapp: json['whatsapp'] as String?,
      instagram: json['instagram'] as String?,
      branches: branchesJson
          .map((b) => PharmacyBranchModel.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}
