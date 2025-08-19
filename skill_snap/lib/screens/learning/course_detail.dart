import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import './course_recommend.dart';

class CourseDetailsSheet extends StatelessWidget {
  final CourseRecommendation recommendation;

  const CourseDetailsSheet({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            recommendation.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Skill: ${recommendation.skill} • ${recommendation.level}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          const Text(
            'About this recommendation:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'This course matches ${recommendation.matchScore}% with your current skill profile '
            'and will help you progress from ${recommendation.level.split('→').first.trim()} '
            'to ${recommendation.level.split('→').last.trim()} level.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openResources(context),
              child: const Text('View All Resources'),
            ),
          ),
        ],
      ),
    );
  }

  void _openResources(BuildContext context) {
    Navigator.pop(context);
    if (recommendation.resources.isNotEmpty) {
      final resource = recommendation.resources.first;
      final url = resource.url ?? _createSearchUrl(resource.name);
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  String _createSearchUrl(String query) {
    return "https://www.udemy.com/courses/search/?q=${Uri.encodeComponent(query)}";
  }
}
