import './challenge_types.dart';

class Spark {
  final String id;
  final String title;
  final String description;
  final String? skillCategory;
  final String difficulty;
  final int durationMinutes;
  final DateTime createdAt;
  final bool isActive;
  final ChallengeData? challengeData; // Add this line

  Spark({
    required this.id,
    required this.title,
    required this.description,
    this.skillCategory,
    required this.difficulty,
    this.durationMinutes = 5,
    required this.createdAt,
    this.isActive = true,
    this.challengeData, // Add this
  });

  factory Spark.fromJson(Map<String, dynamic> json) {
    return Spark(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      skillCategory: json['skill_category'],
      difficulty: json['difficulty'],
      durationMinutes: json['duration_minutes'] ?? 5,
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
      challengeData:
          json['challenge_data'] != null
              ? ChallengeData.fromJson(json['challenge_data'])
              : null, // Add this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'skill_category': skillCategory,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'is_active': isActive,
      'challenge_data': challengeData?.toJson(), // Add this
    };
  }
}
