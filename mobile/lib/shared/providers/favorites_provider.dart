import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/analytics/analytics_tracker.dart';

// ─── Repository ────────────────────────────────────────────────────────────

class _FavoritesApi {
  final _dio = ApiClient().dio;

  Future<Set<String>> fetchAll() async {
    final response = await _dio.get('/favorites');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => '${e['entity_type']}:${e['entity_id']}')
        .toSet();
  }

  Future<void> add(String type, int id) async {
    await _dio.post('/favorites/$type/$id');
  }

  Future<void> remove(String type, int id) async {
    await _dio.delete('/favorites/$type/$id');
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────
// Local keys format: "doctor:123", "clinic:456", "pharmacy:789"

class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const _prefsKey = 'favorites';
  final _api = _FavoritesApi();

  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    // Load from local cache first for instant display
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_prefsKey) ?? [];
    state = Set.from(cached);

    // Then try to sync from backend
    try {
      final remote = await _api.fetchAll();
      state = remote;
      await prefs.setStringList(_prefsKey, remote.toList());
    } catch (_) {
      // Not logged in or network error — stay on local state
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }

  bool isFavorite(String type, int id) => state.contains('$type:$id');

  Future<void> toggle(String type, int id) async {
    final key = '$type:$id';
    final next = Set<String>.from(state);
    final adding = !next.contains(key);

    // Optimistic update
    if (adding) {
      next.add(key);
      AnalyticsTracker().addFavorite(type, id);
    } else {
      next.remove(key);
    }
    state = next;
    await _persist();

    // Sync to backend (silently fail if not authenticated)
    try {
      if (adding) {
        await _api.add(type, id);
      } else {
        await _api.remove(type, id);
      }
    } catch (_) {
      // No auth or network — local-only change is fine
    }
  }

  List<int> idsFor(String type) => state
      .where((k) => k.startsWith('$type:'))
      .map((k) => int.parse(k.split(':')[1]))
      .toList();
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (_) => FavoritesNotifier(),
);

// ─── "Seen" tracking ───────────────────────────────────────────────────────
// Remembers which favorites the user has already viewed on the Favorites
// screen, so the profile badge can show only the count of new ones.

class SeenFavoritesNotifier extends StateNotifier<Set<String>> {
  static const _prefsKey = 'favorites_seen';

  SeenFavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = Set.from(prefs.getStringList(_prefsKey) ?? []);
  }

  Future<void> markAllSeen(Set<String> current) async {
    if (state.length == current.length && state.containsAll(current)) return;
    state = Set.from(current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }
}

final seenFavoritesProvider =
    StateNotifierProvider<SeenFavoritesNotifier, Set<String>>(
  (_) => SeenFavoritesNotifier(),
);

/// Number of favorites the user hasn't viewed on the Favorites screen yet.
final unseenFavoritesCountProvider = Provider<int>((ref) {
  final favorites = ref.watch(favoritesProvider);
  final seen = ref.watch(seenFavoritesProvider);
  return favorites.difference(seen).length;
});
