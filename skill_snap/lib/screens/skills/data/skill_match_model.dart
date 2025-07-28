// skill_match_model.dart
class SkillMatch {
  final String id;
  final String skillId;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String providerId;
  final String message;
  final String? offerSkillName;
  final String? offerSkillTitle;
  final String status;
  final DateTime createdAt;

  SkillMatch({
    required this.id,
    required this.skillId,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    required this.providerId,
    required this.message,
    this.offerSkillName,
    this.offerSkillTitle,
    required this.status,
    required this.createdAt,
  });

  factory SkillMatch.fromJson(Map<String, dynamic> json) {
    return SkillMatch(
      id: json['id'] as String,
      skillId: json['skill_id'] as String,
      requesterId: json['requester_id'] as String,
      requesterName: json['requester']['full_name'] ?? 'Anonymous',
      requesterAvatar: json['requester']['profile_url'],
      providerId: json['provider_id'] as String,
      message: json['message'] as String,
      offerSkillName: json['offer_skill_name'] as String?,
      offerSkillTitle: json['offer_skill']?['title'],
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
