import 'activity_model.dart';
import '../../../services/superbase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

// activity_repository.dart

class ActivityRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Activity>> getRecentActivities(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc(
        'get_recent_activities',
        params: {'p_user_id': userId, 'limit_num': 3},
      );

      if (response == null) return [];
      if (response is! List) return [];

      return (response as List).map((json) {
        final type = json['type'] as String;
        IconData icon;
        Color color;

        switch (type) {
          case 'message':
            icon = Icons.message;
            color = Colors.purple;
            break;
          case 'match':
            icon = Icons.handshake;
            color = Colors.green;
            break;
          case 'rating':
            icon = Icons.star;
            color = Colors.amber;
            break;
          default:
            icon = Icons.notifications;
            color = Colors.blue;
        }

        return Activity(
          id: json['id'] as String,
          type: type,
          title: json['title'] as String,
          subtitle: json['subtitle'] as String,
          // Handle possible null values
          time: DateTime.parse(
            (json['created_at'] ?? DateTime.now().toIso8601String()) as String,
          ),
          icon: icon,
          color: color,
          conversationId: json['conversation_id'] as String?,
          otherUserId: json['other_user_id'] as String?,
          otherUserName: json['other_user_name'] as String?,
          otherUserAvatar: json['other_user_avatar'] as String?,
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('Postgrest Error: ${e.message}');
      return []; // Return empty list to prevent UI crash
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      return [];
    }
  }
}
