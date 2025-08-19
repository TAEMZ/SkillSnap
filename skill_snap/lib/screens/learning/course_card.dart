import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import './course_recommend.dart';
import './resource_model.dart';

class CourseCard extends StatelessWidget {
  final CourseRecommendation recommendation;

  const CourseCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCourseDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(recommendation.skill),
                    backgroundColor: Colors.teal.withOpacity(0.2),
                  ),
                  const Spacer(),
                  _buildMatchScoreIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recommendation.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                recommendation.level,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recommended Resources:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...recommendation.resources.map(_buildResourceTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchScoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${recommendation.matchScore}%',
            style: TextStyle(
              color: _getScoreColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceTile(ResourceLink resource) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(_getResourceIcon(resource.type)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(resource.name, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (recommendation.matchScore > 85) return Colors.green;
    if (recommendation.matchScore > 70) return Colors.teal;
    return Colors.orange;
  }

  IconData _getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.course:
        return Icons.school;
      case ResourceType.video:
        return Icons.play_circle;
      case ResourceType.article:
        return Icons.article;
      case ResourceType.documentation:
        return Icons.description;
    }
  }

  void _showCourseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CourseDetailsSheet(recommendation: recommendation);
      },
    );
  }
}

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
