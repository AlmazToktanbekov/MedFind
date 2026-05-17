import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/clinics_repository.dart';
import '../../../shared/models/clinic_model.dart';

final clinicsRepositoryProvider =
    Provider<ClinicsRepository>((_) => ClinicsRepository());

/// Текущая клиника пользователя (для роли 'clinic'). null если ещё не создана.
final myClinicProvider = FutureProvider<ClinicModel?>((ref) async {
  return ref.read(clinicsRepositoryProvider).getMyClinic();
});

final clinicCategoryProvider = StateProvider<String?>((_) => null);

final clinicsProvider =
    FutureProvider.autoDispose.family<List<ClinicModel>, String?>(
  (ref, category) async {
    final repo = ref.read(clinicsRepositoryProvider);
    return repo.getClinics(category: category);
  },
);

final clinicByIdProvider =
    FutureProvider.autoDispose.family<ClinicModel, int>((ref, id) async {
  final repo = ref.read(clinicsRepositoryProvider);
  return repo.getClinicById(id);
});
