import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_snap/screens/skills/presentation/skill_post_screen.dart';
import '../../../services/superbase_service.dart';
import '../../skills/data/sklil_repository.dart';
import '../data/skill_model.dart';
import 'skill_card.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  late Future<List<Skill>> _skillsFuture;
  final SkillRepository _repository = SkillRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final skills = await _repository.fetchUserSkills(userId);
      if (mounted) {
        setState(() {
          _skillsFuture = Future.value(skills);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _skillsFuture = Future.value([]);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading skills: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSkill(BuildContext context, String skillId) async {
    try {
      setState(() => _isLoading = true);
      await _repository.deleteSkill(skillId);
      await _loadSkills(); // Refresh the list after deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting skill: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Skills')),
      body: RefreshIndicator(
        onRefresh: _loadSkills,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Skill>>(
                  future: _skillsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text('Error: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSkills,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final skills = snapshot.data ?? [];
                    if (skills.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.work_outline, size: 48),
                            const SizedBox(height: 16),
                            const Text('No skills posted yet'),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first skill',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: skills.length,
                      itemBuilder:
                          (context, index) => SkillCard(
                            skill: skills[index],
                            showActions: true,
                            isClickable: false,
                            onDelete:
                                () => _deleteSkill(context, skills[index].id),
                          ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SkillPostScreen()),
            ).then((_) => _loadSkills()),
      ),
    );
  }
}
