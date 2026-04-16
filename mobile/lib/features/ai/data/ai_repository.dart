import '../../../core/network/api_client.dart';

class ChatMessage {
  final String role; // 'user' или 'model'
  final String text;

  const ChatMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

class AiRepository {
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final response = await ApiClient().dio.post(
      '/ai/chat',
      data: {
        'messages': messages.map((m) => m.toJson()).toList(),
      },
    );
    return response.data['reply'] as String;
  }
}
