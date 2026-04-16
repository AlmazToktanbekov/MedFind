class ClinicModel {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? address;
  final String? phone;
  final String? website;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewsCount;
  final String status;
  final String? workingHours;

  const ClinicModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.address,
    this.phone,
    this.website,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.status = 'active',
    this.workingHours,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'] as int,
      name: json['name_ru'] as String? ?? '',
      description: json['description_ru'] as String?,
      category: json['category_ru'] as String?,
      address: json['address_ru'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      photoUrl: json['photo_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      workingHours: json['working_hours_ru'] as String?,
    );
  }
}
