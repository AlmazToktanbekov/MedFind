import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/search_repository.dart';
import '../../../shared/models/doctor_model.dart';
import '../../../shared/models/clinic_model.dart';
import '../../../shared/models/pharmacy_model.dart';

// ─── Status ────────────────────────────────────────────────────────────────

enum SearchStatus { idle, loading, loaded, error }

// ─── State ─────────────────────────────────────────────────────────────────

class SearchState {
  final SearchStatus status;
  final String query;
  final List<DoctorModel> doctors;
  final List<ClinicModel> clinics;
  final List<PharmacyCompanyModel> pharmacies;
  final List<String> history;

  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.doctors = const [],
    this.clinics = const [],
    this.pharmacies = const [],
    this.history = const [],
  });

  bool get hasResults =>
      doctors.isNotEmpty || clinics.isNotEmpty || pharmacies.isNotEmpty;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<DoctorModel>? doctors,
    List<ClinicModel>? clinics,
    List<PharmacyCompanyModel>? pharmacies,
    List<String>? history,
  }) =>
      SearchState(
        status: status ?? this.status,
        query: query ?? this.query,
        doctors: doctors ?? this.doctors,
        clinics: clinics ?? this.clinics,
        pharmacies: pharmacies ?? this.pharmacies,
        history: history ?? this.history,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repo;
  Timer? _debounce;

  static const _historyKey = 'search_history';
  static const _maxHistory = 10;

  SearchNotifier(this._repo) : super(const SearchState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    state = state.copyWith(history: history);
  }

  /// Вызывается при каждом изменении текста в поле поиска
  void onQueryChanged(String query) {
    state = state.copyWith(query: query);

    if (query.trim().isEmpty) {
      _debounce?.cancel();
      state = state.copyWith(
        status: SearchStatus.idle,
        doctors: [],
        clinics: [],
        pharmacies: [],
      );
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(query.trim()),
    );
  }

  /// Тап по элементу истории — поиск без debounce
  void searchFromHistory(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _search(query);
  }

  Future<void> _search(String query) async {
    state = state.copyWith(status: SearchStatus.loading);
    try {
      final results = await _repo.search(query);
      state = state.copyWith(
        status: SearchStatus.loaded,
        doctors: results.doctors,
        clinics: results.clinics,
        pharmacies: results.pharmacies,
      );
      await _saveToHistory(query);
    } catch (_) {
      state = state.copyWith(status: SearchStatus.error);
    }
  }

  Future<void> _saveToHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = List<String>.from(state.history);
    history.remove(query);
    history.insert(0, query);
    if (history.length > _maxHistory) history.removeLast();
    await prefs.setStringList(_historyKey, history);
    state = state.copyWith(history: history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    state = state.copyWith(history: []);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────

final searchRepositoryProvider =
    Provider<SearchRepository>((_) => SearchRepository());

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref.read(searchRepositoryProvider)),
);

final specializationsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.read(searchRepositoryProvider).getSpecializations();
});

final clinicCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.read(searchRepositoryProvider).getCategories();
});
