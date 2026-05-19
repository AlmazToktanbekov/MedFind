import '../../../core/network/api_client.dart';
import 'ai_repository.dart';

// ─── Модель одного диалога ─────────────────────────────────────────────────

class AiConversation {
  final int id;
  final String title;
  final DateTime date;
  final List<ChatMessage> messages;

  const AiConversation({
    required this.id,
    required this.title,
    required this.date,
    required this.messages,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as int,
      title: json['title'] as String,
      date: DateTime.parse(json['updated_at'] as String),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage(
                role: m['role'] as String,
                text: m['text'] as String,
              ))
          .toList(),
    );
  }
}

// ─── Сервис ────────────────────────────────────────────────────────────────

class AiHistoryService {
  final _dio = ApiClient().dio;

  Future<List<AiConversation>> loadHistory() async {
    try {
      final response = await _dio.get('/ai/history');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AiConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AiConversation?> saveConversation(List<ChatMessage> messages) async {
    if (messages.isEmpty) return null;

    final firstUser = messages.firstWhere(
      (m) => m.role == 'user',
      orElse: () => messages.first,
    );
    final title = firstUser.text.length > 45
        ? '${firstUser.text.substring(0, 45)}...'
        : firstUser.text;

    try {
      final response = await _dio.post('/ai/history', data: {
        'title': title,
        'messages': messages.map((m) => {'role': m.role, 'text': m.text}).toList(),
      });
      return AiConversation.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteConversation(int id) async {
    try {
      await _dio.delete('/ai/history/$id');
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _dio.delete('/ai/history');
    } catch (_) {}
  }
}
