// skill_match_model.dart
class SkillMatch {
  final String id;
  final String skillId;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String providerId;
  final String message;
  final DateTime? updatedAt;
  final String? offerSkillName;
  final String? requestedSkillName;

  final String? offerSkillTitle;
  final String status;
  final DateTime createdAt;

  final String providerName; // Add this
  final String? providerAvatar;

  SkillMatch({
    required this.id,
    required this.skillId,
    this.updatedAt,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    required this.providerId,
    this.requestedSkillName,
    required this.message,
    this.offerSkillName,
    this.offerSkillTitle,
    required this.status,
    required this.createdAt,

    required this.providerName,
    this.providerAvatar,
  });

  factory SkillMatch.fromJson(Map<String, dynamic> json) {
    return SkillMatch(
      id: json['id'] as String,
      skillId: json['skill_id'] as String,
      requesterId: json['requester_id'] as String,

      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,

      message: json['message'] as String,
      offerSkillName: json['offer_skill_name'] as String?,
      offerSkillTitle: json['offer_skill']?['title'],
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      requesterName: json['requester']?['full_name'] ?? 'Anonymous',
      requesterAvatar: json['requester']?['profile_url'],
      requestedSkillName: json['requested_skill_name'] as String?,
      providerId: json['provider_id'] as String,
      providerName: json['provider']?['full_name'] ?? 'Unknown',
      providerAvatar: json['provider']?['profile_url'],
    );
  }
}
