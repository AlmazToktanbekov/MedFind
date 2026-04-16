import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/doctors_repository.dart';
import '../../../shared/models/doctor_model.dart';

// ─── Repository ────────────────────────────────────────────────────────────

final doctorsRepositoryProvider =
    Provider<DoctorsRepository>((_) => DoctorsRepository());

// ─── Filter state ──────────────────────────────────────────────────────────

enum DoctorFilter { all, online, clinic }

final doctorFilterProvider = StateProvider<DoctorFilter>((_) => DoctorFilter.all);

// ─── Doctors list ──────────────────────────────────────────────────────────

final doctorsProvider = FutureProvider.autoDispose
    .family<List<DoctorModel>, DoctorFilter>((ref, filter) async {
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctors(
    hasOnline: filter == DoctorFilter.online ? true : null,
  );
});

// ─── Single doctor ─────────────────────────────────────────────────────────

final doctorByIdProvider =
    FutureProvider.autoDispose.family<DoctorModel, int>((ref, id) async {
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctorById(id);
});
