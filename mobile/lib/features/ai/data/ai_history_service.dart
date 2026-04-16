import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_repository.dart';

const _kHistoryKey = 'ai_chat_history';
const _kMaxHistory = 10;

// ─── Модель одного диалога ─────────────────────────────────────────────────

class AiConversation {
  final String id;
  final String title;
  final DateTime date;
  final List<ChatMessage> messages;

  const AiConversation({
    required this.id,
    required this.title,
    required this.date,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'messages': messages
            .map((m) => {'role': m.role, 'text': m.text})
            .toList(),
      };

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
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
  Future<List<AiConversation>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AiConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversation(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;

    // Заголовок = первое сообщение пользователя, обрезать до 45 символов
    final firstUser = messages
        .firstWhere((m) => m.role == 'user', orElse: () => messages.first);
    final title = firstUser.text.length > 45
        ? '${firstUser.text.substring(0, 45)}...'
        : firstUser.text;

    final conversation = AiConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: DateTime.now(),
      messages: messages,
    );

    final history = await loadHistory();

    // Удаляем дубликат если такой же диалог уже есть (по первому сообщению)
    history.removeWhere((c) => c.title == title);

    // Вставляем новый в начало
    history.insert(0, conversation);

    // Оставляем только последние 10
    final trimmed = history.take(_kMaxHistory).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistoryKey, jsonEncode(trimmed.map((c) => c.toJson()).toList()));
  }

  Future<void> deleteConversation(String id) async {
    final history = await loadHistory();
    history.removeWhere((c) => c.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistoryKey, jsonEncode(history.map((c) => c.toJson()).toList()));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }
}
