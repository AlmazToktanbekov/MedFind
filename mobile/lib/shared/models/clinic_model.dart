import '../../core/constants/app_constants.dart';

class ClinicPhotoModel {
  final int id;
  final String url;
  final int order;

  const ClinicPhotoModel(
      {required this.id, required this.url, required this.order});

  factory ClinicPhotoModel.fromJson(Map<String, dynamic> json) =>
      ClinicPhotoModel(
        id: json['id'] as int,
        url: AppConstants.fixUrl(json['url'] as String),
        order: json['order'] as int? ?? 0,
      );
}

class ClinicModel {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? telegram;
  final String? instagram;
  final String? email;
  final String? website;
  final String? photoUrl;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final double rating;
  final int reviewsCount;
  final String status;
  final String? workingHours;
  final List<ClinicPhotoModel> photos;

  const ClinicModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.address,
    this.phone,
    this.whatsapp,
    this.telegram,
    this.instagram,
    this.email,
    this.website,
    this.photoUrl,
    this.logoUrl,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.status = 'active',
    this.workingHours,
    this.photos = const [],
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? [];
    return ClinicModel(
      id: json['id'] as int,
      name: json['name_ru'] as String? ?? '',
      description: json['description_ru'] as String?,
      category: json['category_ru'] as String?,
      address: json['address_ru'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      telegram: json['telegram'] as String?,
      instagram: json['instagram'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      photoUrl: AppConstants.fixUrlOrNull(json['photo_url'] as String?),
      logoUrl: AppConstants.fixUrlOrNull(json['logo_url'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapUrl: json['map_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      workingHours: json['working_hours_ru'] as String?,
      photos: rawPhotos
          .map((e) => ClinicPhotoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
