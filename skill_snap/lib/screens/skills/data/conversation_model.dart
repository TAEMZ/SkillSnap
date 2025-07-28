// conversation_model.dart
class Conversation {
  final String id;
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadMessagesCount;

  Conversation({
    required this.matchId,
    required this.otherUserId,
    required this.id,
    required this.otherUserName,
    this.unreadMessagesCount = 0,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      otherUserId: json['other_user_id']?.toString() ?? '',
      otherUserName: json['other_user_name'] ?? 'Unknown',
      otherUserAvatar: json['other_user_avatar'],
      lastMessage: json['last_message'] ?? '',
      lastMessageTime:
          json['last_message_time'] != null
              ? DateTime.parse(json['last_message_time'])
              : DateTime.now(),
      unreadMessagesCount: json['unread_count'] as int? ?? 0,
    );
  }
}
