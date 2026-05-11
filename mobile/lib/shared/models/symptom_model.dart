class SymptomModel {
  final int id;
  final String nameRu;
  final String? nameKg;
  final String? nameEn;
  final String? icon;

  const SymptomModel({
    required this.id,
    required this.nameRu,
    this.nameKg,
    this.nameEn,
    this.icon,
  });

  factory SymptomModel.fromJson(Map<String, dynamic> j) => SymptomModel(
        id: j['id'] as int,
        nameRu: j['name_ru'] as String,
        nameKg: j['name_kg'] as String?,
        nameEn: j['name_en'] as String?,
        icon: j['icon'] as String?,
      );
}
