import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/superbase_service.dart';
import '../data/sklil_repository.dart';
import '../data/skill_model.dart';
import 'skill_card.dart';
import 'skill_post_screen.dart';
import 'skill_details_screen.dart';

class SkillListScreen extends StatefulWidget {
  final bool showOnlyUserSkills;

  const SkillListScreen({super.key, this.showOnlyUserSkills = false});

  @override
  State<SkillListScreen> createState() => _SkillListScreenState();
}

class _SkillListScreenState extends State<SkillListScreen> {
  final SkillRepository _repository = SkillRepository();
  late Future<List<Skill>> _skillsFuture;
  String? _typeFilter;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = SupabaseService.client.auth.currentUser?.id;
    _refreshSkills();
  }

  Future<void> _refreshSkills() async {
    setState(() {
      if (widget.showOnlyUserSkills && _userId != null) {
        _skillsFuture = _repository.fetchUserSkills(_userId!);
      } else {
        _skillsFuture = _repository.fetchSkills(
          typeFilter: _typeFilter,
          excludeCurrentUser: !widget.showOnlyUserSkills,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showOnlyUserSkills ? 'My Skills' : 'Skills Marketplace',
        ),
        actions:
            widget.showOnlyUserSkills
                ? null
                : [
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    onPressed: () => _showFilterDialog(context),
                  ),
                ],
      ),
      floatingActionButton:
          widget.showOnlyUserSkills
              ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkillPostScreen(),
                      ),
                    ).then((_) => _refreshSkills()),
              )
              : null,
      body: RefreshIndicator(
        onRefresh: _refreshSkills,
        child: FutureBuilder<List<Skill>>(
          future: _skillsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return _buildSkillList(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildSkillList(List<Skill> skills) {
    if (skills.isEmpty) {
      return Center(
        child: Text(
          widget.showOnlyUserSkills
              ? 'You haven\'t posted any skills yet'
              : 'No skills found',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: skills.length,
      // In _buildSkillList method:
      itemBuilder:
          (context, index) => SkillCard(
            skill: skills[index],
            isClickable: true, // Enable tapping
            onTap: () => _showSkillDetails(context, skills[index]),
            showActions: false, // No delete in marketplace
          ),
    );
  }

  Future<void> _deleteSkill(BuildContext context, String skillId) async {
    try {
      await _repository.deleteSkill(skillId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill deleted successfully')),
        );
        _refreshSkills();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting skill: ${e.toString()}')),
        );
      }
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Filter Skills'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String?>(
                  value: null,
                  groupValue: _typeFilter,
                  title: const Text('All Skills'),
                  onChanged: (value) => _updateFilter(value),
                ),
                RadioListTile<String?>(
                  value: 'offer',
                  groupValue: _typeFilter,
                  title: const Text('Offers Only'),
                  onChanged: (value) => _updateFilter(value),
                ),
                RadioListTile<String?>(
                  value: 'request',
                  groupValue: _typeFilter,
                  title: const Text('Requests Only'),
                  onChanged: (value) => _updateFilter(value),
                ),
              ],
            ),
          ),
    );
  }

  void _updateFilter(String? value) {
    setState(() {
      _typeFilter = value;
      _refreshSkills();
      Navigator.pop(context);
    });
  }

  void _showSkillDetails(BuildContext context, Skill skill) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SkillDetailScreen(skill: skill)),
    );
  }
}
