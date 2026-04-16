import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_history_service.dart';

final aiHistoryServiceProvider =
    Provider<AiHistoryService>((_) => AiHistoryService());

// ─── Список истории ────────────────────────────────────────────────────────

class AiHistoryNotifier extends StateNotifier<AsyncValue<List<AiConversation>>> {
  final AiHistoryService _service;

  AiHistoryNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final history = await _service.loadHistory();
      state = AsyncValue.data(history);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(List<dynamic> messages) async {
    await _service.saveConversation(messages.cast());
    await load();
  }

  Future<void> delete(String id) async {
    await _service.deleteConversation(id);
    await load();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    await load();
  }
}

final aiHistoryProvider = StateNotifierProvider<AiHistoryNotifier,
    AsyncValue<List<AiConversation>>>(
  (ref) => AiHistoryNotifier(ref.read(aiHistoryServiceProvider)),
);
