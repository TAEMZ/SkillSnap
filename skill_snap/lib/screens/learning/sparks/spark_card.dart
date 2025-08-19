import 'package:flutter/material.dart';
import '../sparks/sparks_model.dart';

class SparkCardWidget extends StatelessWidget {
  final Spark spark;
  final VoidCallback onTap;
  final int index;

  const SparkCardWidget({
    super.key,
    required this.spark,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[850]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getDifficultyColor(spark.difficulty).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildTitle(),
                const SizedBox(height: 12),
                _buildDescription(),
                if (spark.skillCategory != null) ...[
                  const SizedBox(height: 16),
                  _buildSkillCategory(),
                ],
                const SizedBox(height: 20),
                _buildProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getDifficultyColor(spark.difficulty).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getSparkIcon(spark.skillCategory),
            color: _getDifficultyColor(spark.difficulty),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              _buildBadge('${spark.durationMinutes} min', Colors.blue[400]!),
              const SizedBox(width: 8),
              _buildBadge(
                spark.difficulty.toUpperCase(),
                _getDifficultyColor(spark.difficulty),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      spark.title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      spark.description,
      style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
    );
  }

  Widget _buildSkillCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[400]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[400]!),
      ),
      child: Text(
        spark.skillCategory!,
        style: TextStyle(
          color: Colors.blue[400],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: 0.0, // Start at 0, will be 1.0 when completed
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getDifficultyColor(spark.difficulty),
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getSparkIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'design':
        return Icons.palette;
      case 'coding':
      case 'programming':
        return Icons.code;
      case 'writing':
        return Icons.edit;
      case 'fitness':
        return Icons.fitness_center;
      case 'music':
        return Icons.music_note;
      case 'language':
        return Icons.translate;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green[400]!;
      case 'intermediate':
        return Colors.orange[400]!;
      case 'advanced':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
  }
}
