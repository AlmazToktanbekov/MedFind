import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/doctors_repository.dart';
import '../../../shared/models/doctor_model.dart';
import '../../../shared/models/symptom_model.dart';
import '../../../core/network/api_client.dart';

// ─── Repository ────────────────────────────────────────────────────────────

final doctorsRepositoryProvider =
    Provider<DoctorsRepository>((_) => DoctorsRepository());

// ─── Filter state ──────────────────────────────────────────────────────────

enum DoctorFilter { all, online }

final doctorFilterProvider = StateProvider<DoctorFilter>((_) => DoctorFilter.all);

final doctorSpecializationProvider = StateProvider<String?>((_) => null);

// ─── Doctors list ──────────────────────────────────────────────────────────

final doctorsProvider = FutureProvider.autoDispose<List<DoctorModel>>((ref) async {
  final filter = ref.watch(doctorFilterProvider);
  final specialization = ref.watch(doctorSpecializationProvider);
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctors(
    hasOnline: filter == DoctorFilter.online ? true : null,
    specialization: specialization,
  );
});

// ─── Single doctor ─────────────────────────────────────────────────────────

final doctorByIdProvider =
    FutureProvider.autoDispose.family<DoctorModel, int>((ref, id) async {
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctorById(id);
});

// ─── Doctors by symptom ────────────────────────────────────────────────────

final doctorsBySymptomProvider =
    FutureProvider.autoDispose.family<List<DoctorModel>, int>((ref, symptomId) async {
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctorsBySymptom(symptomId);
});

// ─── Doctors by specialization ─────────────────────────────────────────────

final doctorsBySpecializationProvider =
    FutureProvider.autoDispose.family<List<DoctorModel>, String>((ref, spec) async {
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctors(specialization: spec);
});

// ─── Symptoms list ─────────────────────────────────────────────────────────

final symptomsProvider = FutureProvider<List<SymptomModel>>((ref) async {
  final dio = ApiClient().dio;
  final response = await dio.get('/symptoms');
  final list = response.data as List<dynamic>;
  return list.map((e) => SymptomModel.fromJson(e as Map<String, dynamic>)).toList();
});
