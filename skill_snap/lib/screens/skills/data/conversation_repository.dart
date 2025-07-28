import 'package:supabase_flutter/supabase_flutter.dart';
import 'conversation_model.dart';
import '../data/message_model.dart';

// conversation_repository.dart
class ConversationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> createConversation({
    required String matchId,
    required String user1,
    required String user2,
  }) async {
    final response = await _client
        .from('conversations')
        .insert({
          'match_id': matchId,
          'user1': user1,
          'user2': user2,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .select('id');

    return response.first['id'] as String;
  }

  Future<Conversation> getConversationById(String conversationId) async {
    final response =
        await _client
            .from('conversations')
            .select()
            .eq('id', conversationId)
            .single();

    return Conversation.fromJson(response);
  }

  Stream<List<Conversation>> getConversations(String userId) {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((data) {
          return data
              .where((row) => row['user1'] == userId || row['user2'] == userId)
              .map((row) {
                final otherUserId =
                    row['user1'] == userId ? row['user2'] : row['user1'];
                return Conversation.fromJson({
                  ...row,
                  'other_user_id': otherUserId,
                  'unread_count': row['unread_count'] ?? 0, // Add this
                });
              })
              .toList();
        });
  }
}
