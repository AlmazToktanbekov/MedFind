class PharmacyModel {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final bool isOpen24h;
  final String? workingHours;
  final String status;
  final double? distanceKm;

  const PharmacyModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.isOpen24h = false,
    this.workingHours,
    this.status = 'active',
    this.distanceKm,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as int,
      name: json['name_ru'] as String? ?? '',
      address: json['address_ru'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isOpen24h: json['is_open_24h'] as bool? ?? false,
      workingHours: json['working_hours_ru'] as String?,
      status: json['status'] as String? ?? 'active',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}
