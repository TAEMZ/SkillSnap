import './resource_model.dart';

class CourseRecommendation {
  final String title;
  final String skill;
  final String level;
  final List<ResourceLink> resources;
  final int matchScore;

  CourseRecommendation({
    required this.title,
    required this.skill,
    required this.level,
    required this.resources,
    required this.matchScore,
  });

  factory CourseRecommendation.fromJson(Map<String, dynamic> json) {
    return CourseRecommendation(
      title: json['title'],
      skill: json['skill'],
      level: json['level'],
      matchScore: json['match_score'],
      resources:
          (json['resources'] as List)
              .map((r) => ResourceLink.fromJson(r))
              .toList(),
    );
  }
}
