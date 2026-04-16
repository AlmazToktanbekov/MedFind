import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pharmacies_repository.dart';
import '../../../shared/models/pharmacy_model.dart';

final pharmaciesRepositoryProvider =
    Provider<PharmaciesRepository>((_) => PharmaciesRepository());

final pharmaciesProvider =
    FutureProvider.autoDispose<List<PharmacyModel>>((ref) async {
  final repo = ref.read(pharmaciesRepositoryProvider);
  return repo.getPharmacies();
});

final pharmacyByIdProvider =
    FutureProvider.autoDispose.family<PharmacyModel, int>((ref, id) async {
  final repo = ref.read(pharmaciesRepositoryProvider);
  return repo.getPharmacyById(id);
});
