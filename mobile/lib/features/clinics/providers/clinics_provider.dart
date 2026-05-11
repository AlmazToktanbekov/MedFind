import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/clinics_repository.dart';
import '../../../shared/models/clinic_model.dart';

final clinicsRepositoryProvider =
    Provider<ClinicsRepository>((_) => ClinicsRepository());

final clinicCategoryProvider = StateProvider<String?>((_) => null);

enum ClinicListMode { all, nearby }

final clinicListModeProvider =
    StateProvider<ClinicListMode>((_) => ClinicListMode.all);

final clinicsProvider =
    FutureProvider.autoDispose.family<List<ClinicModel>, String?>(
  (ref, category) async {
    final repo = ref.read(clinicsRepositoryProvider);
    return repo.getClinics(category: category);
  },
);

final nearbyClinicsProvider =
    FutureProvider.autoDispose<List<ClinicModel>>((ref) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Нет доступа к геолокации');
  }
  final pos = await Geolocator.getCurrentPosition();
  final repo = ref.read(clinicsRepositoryProvider);
  return repo.getNearbyClinics(lat: pos.latitude, lon: pos.longitude);
});

final clinicByIdProvider =
    FutureProvider.autoDispose.family<ClinicModel, int>((ref, id) async {
  final repo = ref.read(clinicsRepositoryProvider);
  return repo.getClinicById(id);
});
