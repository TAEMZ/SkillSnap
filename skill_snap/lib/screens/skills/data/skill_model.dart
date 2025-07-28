class Skill {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String? userAvatar;
  final String title;
  final String? description;
  final String type;
  final List<String>? evidenceUrls;
  final List<String>? exchangeSkills;
  final DateTime createdAt;
  final String? requestedSkill;

  Skill({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userAvatar,
    required this.title,
    this.description,
    required this.type,
    this.evidenceUrls,
    this.exchangeSkills,
    required this.createdAt,
    this.requestedSkill,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    // Handle potential null values and type conversions
    return Skill(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userEmail: (json['user']?['email'] ?? '') as String,
      userName: (json['user']?['full_name'] ?? 'Anonymous') as String,
      userAvatar: json['user']?['profile_url'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'offer', // Default to 'offer' if null
      evidenceUrls:
          json['evidence_urls'] != null
              ? List<String>.from(json['evidence_urls'] as List? ?? [])
              : null,
      exchangeSkills:
          json['exchange_skills'] != null
              ? List<String>.from(json['exchange_skills'] as List? ?? [])
              : null,
      requestedSkill: json['requested_skill'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'type': type,
    'evidence_urls': evidenceUrls,
    'exchange_skills': exchangeSkills,
    'requested_skill': requestedSkill,
    'created_at': createdAt.toIso8601String(),
  };
}
