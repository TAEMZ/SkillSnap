import '../data/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// message_repository.dart
// message_repository.dart
class MessageRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Message>> getMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: false)
        .map((data) => data.map(Message.fromJson).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'is_read': false,
    });

    // Update conversation last message timestamp
    await _client
        .from('conversations')
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _client.from('messages').update({'is_read': true}).match({
      'conversation_id': conversationId,
      'sender_id': userId,
      'is_read': false,
    });
  }
}
