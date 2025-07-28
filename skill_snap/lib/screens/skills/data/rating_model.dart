class Rating {
  final String id;
  final String skillId;
  final String fromUser; // Changed from fromUserId
  final String fromUserName;
  final String? fromUserAvatar;
  final String toUser; // Changed from toUserId
  final int rating;
  final String? feedback; // Changed from comment
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.skillId,
    required this.fromUser,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.toUser,
    required this.rating,
    this.feedback,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      skillId: json['skill_id'] as String,
      fromUser: json['from_user'] as String, // Changed
      fromUserName: json['from_user_data']['full_name'] ?? 'Anonymous',
      fromUserAvatar: json['from_user_data']['profile_url'],
      toUser: json['to_user'] as String, // Changed
      rating: json['rating'] as int,
      feedback: json['feedback'] as String?, // Changed
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
