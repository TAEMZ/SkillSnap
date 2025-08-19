import 'package:flutter/material.dart';

class GemsScreen extends StatefulWidget {
  const GemsScreen({super.key});

  @override
  State<GemsScreen> createState() => _GemsScreenState();
}

class _GemsScreenState extends State<GemsScreen> {
  final List<SkillGem> _gems = [
    SkillGem(
      skill: "React",
      level: "Intermediate",
      evidence: "Explained useState hook to Alex",
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: GemType.technical,
    ),
    SkillGem(
      skill: "Teaching",
      level: "Beginner",
      evidence: "Guided through debugging process",
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: GemType.teaching,
    ),
    SkillGem(
      skill: "UI Design",
      level: "Advanced",
      evidence: "Shared Figma shortcuts in group chat",
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: GemType.creative,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gems")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _gems.length,
        itemBuilder: (context, index) {
          return GemCard(gem: _gems[index]);
        },
      ),
    );
  }
}

class GemCard extends StatelessWidget {
  final SkillGem gem;

  const GemCard({super.key, required this.gem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getGemColor(gem.type).withOpacity(0.2),
              ),
              child: Icon(Icons.diamond, color: _getGemColor(gem.type)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gem.skill,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("${gem.level} level"),
                  const SizedBox(height: 8),
                  Text(
                    gem.evidence,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(gem.date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.teal,
              onPressed: () => _addToProfile(gem),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGemColor(GemType type) {
    switch (type) {
      case GemType.technical:
        return Colors.blue;
      case GemType.teaching:
        return Colors.green;
      case GemType.creative:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _addToProfile(SkillGem gem) {
    // TODO: Implement adding to profile
  }
}

class SkillGem {
  final String skill;
  final String level;
  final String evidence;
  final DateTime date;
  final GemType type;

  SkillGem({
    required this.skill,
    required this.level,
    required this.evidence,
    required this.date,
    required this.type,
  });
}

enum GemType { technical, teaching, creative }
