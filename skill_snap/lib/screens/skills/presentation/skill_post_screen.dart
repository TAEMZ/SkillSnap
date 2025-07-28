import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/superbase_service.dart';
import '../data/skill_model.dart';
import '../data/sklil_repository.dart';
import '../../profile/profile_repository.dart';
import '../../auth/auth_controller.dart';

class SkillPostScreen extends StatefulWidget {
  final Skill? skill;

  const SkillPostScreen({super.key, this.skill});

  @override
  State<SkillPostScreen> createState() => _SkillPostScreenState();
}

class _SkillPostScreenState extends State<SkillPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _evidenceController = TextEditingController();
  String _type = 'offer';
  bool _isSubmitting = false;
  List<String> _evidenceLinks = [];
  List<String> _profileSkills = [];
  List<String> _selectedExchangeSkills = [];

  @override
  void initState() {
    super.initState();
    _loadProfileSkills();
    if (widget.skill != null) {
      _titleController.text = widget.skill!.title;
      _descController.text = widget.skill!.description ?? '';
      _type = widget.skill!.type;
      _evidenceLinks = widget.skill!.evidenceUrls ?? [];
    }
  }

  Future<void> _loadProfileSkills() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final profile = await ProfileRepository().getProfile(userId);
    if (profile != null && profile['skills'] != null) {
      setState(() {
        _profileSkills = List<String>.from(profile['skills']);
      });
    }
  }

  void _addEvidence() {
    if (_evidenceController.text.trim().isNotEmpty) {
      setState(() {
        _evidenceLinks.add(_evidenceController.text.trim());
        _evidenceController.clear();
      });
    }
  }

  void _removeEvidence(int index) {
    setState(() => _evidenceLinks.removeAt(index));
  }

  void _toggleExchangeSkill(String skill) {
    setState(() {
      if (_selectedExchangeSkills.contains(skill)) {
        _selectedExchangeSkills.remove(skill);
      } else {
        _selectedExchangeSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill == null ? 'Post Skill' : 'Edit Skill'),
        actions: [
          IconButton(
            icon:
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.check),
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill Type Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'offer',
                          label: Text('Offering'),
                          icon: Icon(Icons.share),
                        ),
                        ButtonSegment(
                          value: 'request',
                          label: Text('Requesting'),
                          icon: Icon(Icons.search),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _type = newSelection.first);
                      },
                    ),
                  ),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Skill Title*',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Exchange Skills Section (for requests)
                  if (_type == 'request' && _profileSkills.isNotEmpty) ...[
                    const Text(
                      'Skills I Can Offer in Exchange:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          _profileSkills
                              .map(
                                (skill) => FilterChip(
                                  label: Text(skill),
                                  selected: _selectedExchangeSkills.contains(
                                    skill,
                                  ),
                                  onSelected:
                                      (_) => _toggleExchangeSkill(skill),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Evidence Section
                  const Text(
                    'Verification Evidence (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add links to portfolios, certifications, or work samples',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Evidence Input
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _evidenceController,
                          decoration: InputDecoration(
                            labelText: 'Add URL',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_link),
                              onPressed: _addEvidence,
                            ),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ),
                    ],
                  ),

                  // Evidence Chips
                  if (_evidenceLinks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_evidenceLinks.length, (index) {
                        return InputChip(
                          label: Text(
                            _evidenceLinks[index],
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () => _removeEvidence(index),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Submit Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingActionButton.extended(
                onPressed: _isSubmitting ? null : _submit,
                backgroundColor: const Color(0xFF00796B),
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  widget.skill == null ? 'POST SKILL' : 'UPDATE SKILL',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final repository = SkillRepository();

      if (widget.skill == null) {
        await repository.createSkill(
          title: _titleController.text,
          type: _type,
          description:
              _descController.text.isNotEmpty ? _descController.text : null,
          evidenceUrls: _evidenceLinks.isNotEmpty ? _evidenceLinks : null,
          exchangeSkills:
              _type == 'request' && _selectedExchangeSkills.isNotEmpty
                  ? _selectedExchangeSkills
                  : null,
        );
      } else {
        await repository.updateSkill(
          skillId: widget.skill!.id,
          title: _titleController.text,
          description:
              _descController.text.isNotEmpty ? _descController.text : null,
          evidenceUrls: _evidenceLinks.isNotEmpty ? _evidenceLinks : null,
          exchangeSkills:
              _type == 'request' && _selectedExchangeSkills.isNotEmpty
                  ? _selectedExchangeSkills
                  : null,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.skill == null
                  ? 'Skill posted successfully!'
                  : 'Skill updated successfully!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
