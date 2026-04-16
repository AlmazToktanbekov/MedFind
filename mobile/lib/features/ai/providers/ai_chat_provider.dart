import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_repository.dart';
import '../data/ai_history_service.dart';
import 'ai_history_provider.dart';

// ─── Repository provider ───────────────────────────────────────────────────

final aiRepositoryProvider = Provider<AiRepository>((_) => AiRepository());

// ─── Chat state ────────────────────────────────────────────────────────────

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiRepository _repo;
  final Ref _ref;

  AiChatNotifier(this._repo, this._ref) : super(const AiChatState());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(role: 'user', text: text.trim());
    final updatedMessages = [...state.messages, userMsg];

    state = state.copyWith(messages: updatedMessages, isLoading: true);

    try {
      final reply = await _repo.sendMessage(updatedMessages);
      final modelMsg = ChatMessage(role: 'model', text: reply);
      final finalMessages = [...updatedMessages, modelMsg];

      state = state.copyWith(messages: finalMessages, isLoading: false);

      // Автосохранение в историю после каждого ответа AI
      await _ref.read(aiHistoryProvider.notifier).save(finalMessages);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось получить ответ. Попробуйте ещё раз.',
      );
    }
  }

  // Загрузить диалог из истории
  void loadConversation(AiConversation conversation) {
    state = AiChatState(messages: List.from(conversation.messages));
  }

  void clearError() => state = state.copyWith(error: null);

  void reset() => state = const AiChatState();
}

// ─── Provider ──────────────────────────────────────────────────────────────

final aiChatProvider =
    StateNotifierProvider.autoDispose<AiChatNotifier, AiChatState>(
  (ref) => AiChatNotifier(ref.read(aiRepositoryProvider), ref),
);
