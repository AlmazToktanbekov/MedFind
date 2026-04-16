import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Формат хранения ───────────────────────────────────────────────────────
// SharedPreferences: List<String> с ключами вида "doctor:123", "clinic:456"

class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const _prefsKey = 'favorites';

  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    state = Set.from(list);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }

  bool isFavorite(String type, int id) => state.contains('$type:$id');

  Future<void> toggle(String type, int id) async {
    final key = '$type:$id';
    final next = Set<String>.from(state);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    state = next;
    await _persist();
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
