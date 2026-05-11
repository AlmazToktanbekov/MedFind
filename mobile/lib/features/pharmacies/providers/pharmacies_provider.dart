import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/pharmacies_repository.dart';
import '../../../shared/models/pharmacy_model.dart';

final pharmaciesRepositoryProvider =
    Provider<PharmaciesRepository>((_) => PharmaciesRepository());

// Все филиалы (обычный список)
final branchesProvider =
    FutureProvider.autoDispose<List<PharmacyBranchModel>>((ref) async {
  return ref.read(pharmaciesRepositoryProvider).getBranches();
});

// Ближайшие филиалы
final nearbyBranchesProvider =
    FutureProvider.autoDispose<List<PharmacyBranchModel>>((ref) async {
  final position = await _determinePosition();
  return ref.read(pharmaciesRepositoryProvider).getNearbyBranches(
        lat: position.latitude,
        lng: position.longitude,
      );
});

// Один филиал по id
final branchByIdProvider =
    FutureProvider.autoDispose.family<PharmacyBranchModel, int>((ref, id) async {
  return ref.read(pharmaciesRepositoryProvider).getBranchById(id);
});

// Компания по id (со всеми филиалами)
final companyByIdProvider =
    FutureProvider.autoDispose.family<PharmacyCompanyModel, int>((ref, id) async {
  return ref.read(pharmaciesRepositoryProvider).getCompanyById(id);
});

// Режим экрана аптек: обычный список или ближайшие
enum PharmacyListMode { all, nearby }

final pharmacyListModeProvider =
    StateProvider<PharmacyListMode>((_) => PharmacyListMode.all);

// Поисковый запрос на экране аптек
final pharmacySearchQueryProvider = StateProvider<String>((_) => '');

// ─── Геолокация ────────────────────────────────────────────────────────────

/// Что именно пошло не так с геолокацией — чтобы UI мог предложить действие.
enum LocationErrorKind {
  /// Геолокация выключена в настройках устройства.
  serviceDisabled,

  /// Пользователь отклонил запрос разрешения (можно спросить снова).
  denied,

  /// Доступ запрещён навсегда — нужно открыть настройки приложения.
  deniedForever,
}

class LocationException implements Exception {
  final LocationErrorKind kind;
  final String message;
  const LocationException(this.kind, this.message);

  @override
  String toString() => message;
}

Future<Position> _determinePosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const LocationException(
      LocationErrorKind.serviceDisabled,
      'Геолокация отключена на устройстве. Включите её в настройках.',
    );
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationErrorKind.denied,
        'Чтобы показать ближайшие аптеки, разрешите доступ к геолокации.',
      );
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationException(
      LocationErrorKind.deniedForever,
      'Доступ к геолокации запрещён. Разрешите его в настройках приложения.',
    );
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
