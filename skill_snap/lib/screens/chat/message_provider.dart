import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/superbase_service.dart';
import '../../screens/skills/data/conversation_repository.dart';
import '../skills/data/conversation_model.dart';

class MessageProvider with ChangeNotifier {
  int _unreadCount = 0;
  List<Conversation> _conversations = [];

  int get unreadCount => _unreadCount;
  List<Conversation> get conversations => _conversations;

  Future<void> loadUnreadCount() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final repo = ConversationRepository();
      final conversations = await repo.getConversations(userId).first;

      _unreadCount = conversations.fold(0, (count, conversation) {
        // Add null check
        return count + (conversation.unreadMessagesCount);
      });

      _conversations = conversations;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Stream<List<Conversation>> get conversationsStream {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return Supabase.instance.client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((data) => data.map(Conversation.fromJson).toList());
  }

  void updateUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}
