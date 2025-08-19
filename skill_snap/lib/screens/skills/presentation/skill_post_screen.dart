import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SkillPostScreenState extends State<SkillPostScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _evidenceController = TextEditingController();
  String _type = 'offer';
  bool _isSubmitting = false;
  List<String> _evidenceLinks = [];
  List<String> _profileSkills = [];
  List<String> _selectedExchangeSkills = [];
  String? _exchangeSkillsError;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadProfileSkills();
    if (widget.skill != null) {
      _titleController.text = widget.skill!.title;
      _descController.text = widget.skill!.description ?? '';
      _type = widget.skill!.type;
      _evidenceLinks = widget.skill!.evidenceUrls ?? [];
      _selectedExchangeSkills = widget.skill!.exchangeSkills ?? [];
    }
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileSkills() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profile = await ProfileRepository().getProfile(userId);
      if (profile != null && profile['skills'] != null) {
        if (mounted) {
          setState(() {
            _profileSkills = List<String>.from(profile['skills']);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error loading profile skills: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _addEvidence() {
    final url = _evidenceController.text.trim();
    if (url.isNotEmpty && _validateUrl(url)) {
      HapticFeedback.lightImpact();
      setState(() {
        _evidenceLinks.add(url);
        _evidenceController.clear();
      });
    } else {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Please enter a valid URL'),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _removeEvidence(int index) {
    HapticFeedback.lightImpact();
    setState(() => _evidenceLinks.removeAt(index));
  }

  void _toggleExchangeSkill(String skill) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedExchangeSkills.contains(skill)) {
        _selectedExchangeSkills.remove(skill);
      } else {
        _selectedExchangeSkills.add(skill);
      }
      _exchangeSkillsError = _validateExchangeSkills();
    });
  }

  bool _validateUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String? _validateExchangeSkills() {
    if (_type == 'request' && _selectedExchangeSkills.isEmpty) {
      return 'Please select at least one skill to offer in exchange';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _exchangeSkillsError = _validateExchangeSkills();
    });

    if (!_formKey.currentState!.validate() || _exchangeSkillsError != null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Please fix the errors in the form'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.skill == null
                      ? 'Skill posted successfully! 🎉'
                      : 'Skill updated successfully! ✨',
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey, Colors.white12],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTypeSelector(),
                            const SizedBox(height: 24),
                            _buildTitleField(),
                            const SizedBox(height: 20),
                            _buildDescriptionField(),
                            const SizedBox(height: 24),
                            if (_type == 'request')
                              _buildExchangeSkillsSection(),
                            _buildEvidenceSection(),
                            const SizedBox(height: 32),
                            _buildSubmitButton(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.skill == null ? 'Post New Skill' : 'Edit Skill',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed:
            _isSubmitting
                ? null
                : () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[700]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.greenAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                'What are you doing?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _type = 'offer';
                      _exchangeSkillsError = _validateExchangeSkills();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient:
                          _type == 'offer'
                              ? LinearGradient(
                                colors: [
                                  Colors.greenAccent,
                                  Colors.green[600]!,
                                ],
                              )
                              : null,
                      color: _type == 'offer' ? null : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _type == 'offer'
                                ? Colors.greenAccent
                                : Colors.grey[600]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.share,
                          color:
                              _type == 'offer'
                                  ? Colors.black
                                  : Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Offering',
                          style: TextStyle(
                            color:
                                _type == 'offer'
                                    ? Colors.black
                                    : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share your expertise',
                          style: TextStyle(
                            color:
                                _type == 'offer'
                                    ? Colors.black87
                                    : Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _type = 'request';
                      _exchangeSkillsError = _validateExchangeSkills();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient:
                          _type == 'request'
                              ? LinearGradient(
                                colors: [
                                  Colors.orange[400]!,
                                  Colors.orange[600]!,
                                ],
                              )
                              : null,
                      color: _type == 'request' ? null : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _type == 'request'
                                ? Colors.orange[400]!
                                : Colors.grey[600]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search,
                          color:
                              _type == 'request'
                                  ? Colors.black
                                  : Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Requesting',
                          style: TextStyle(
                            color:
                                _type == 'request'
                                    ? Colors.black
                                    : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Looking for help',
                          style: TextStyle(
                            color:
                                _type == 'request'
                                    ? Colors.black87
                                    : Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: TextFormField(
        controller: _titleController,
        enabled: !_isSubmitting,
        decoration: InputDecoration(
          labelText: 'Skill Title *',
          labelStyle: TextStyle(color: Colors.greenAccent),
          prefixIcon: Icon(Icons.title, color: Colors.greenAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.greenAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          hintText:
              _type == 'offer'
                  ? 'e.g., Web Development, Guitar Lessons, Photography'
                  : 'e.g., Need help with React, Looking for Spanish tutor',
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Skill title is required';
          }
          if (value.length < 3) {
            return 'Title must be at least 3 characters';
          }
          if (value.length > 100) {
            return 'Title must be less than 100 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: TextFormField(
        controller: _descController,
        enabled: !_isSubmitting,
        decoration: InputDecoration(
          labelText: 'Description (Optional)',
          labelStyle: TextStyle(color: Colors.greenAccent),
          prefixIcon: Icon(Icons.description, color: Colors.greenAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.greenAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          hintText:
              _type == 'offer'
                  ? 'Describe your expertise, experience level, and what you can teach...'
                  : 'Explain what you need help with, your current level, and learning goals...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          alignLabelWithHint: true,
        ),
        style: const TextStyle(fontSize: 16, color: Colors.white),
        maxLines: 4,
        minLines: 3,
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            if (value.length < 10) {
              return 'Description must be at least 10 characters';
            }
            if (value.length > 500) {
              return 'Description must be less than 500 characters';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildExchangeSkillsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange[900]!.withOpacity(0.3),
            Colors.orange[800]!.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[400]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.orange[400], size: 24),
              const SizedBox(width: 12),
              Text(
                'Skills I Can Offer in Exchange',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select skills from your profile that you can teach in return',
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_profileSkills.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No skills available. Add skills to your profile first.',
                      style: TextStyle(color: Colors.blue[400], fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _profileSkills.asMap().entries.map((entry) {
                    final index = entry.key;
                    final skill = entry.value;
                    final isSelected = _selectedExchangeSkills.contains(skill);

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: FilterChip(
                            label: Text(
                              skill,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => _toggleExchangeSkill(skill),
                            backgroundColor: Colors.grey[800],
                            selectedColor: Colors.greenAccent,
                            checkmarkColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? Colors.greenAccent
                                        : Colors.grey[600]!,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
          if (_exchangeSkillsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[900]!.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[400]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _exchangeSkillsError!,
                        style: TextStyle(color: Colors.red[400], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[700]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.blue[400], size: 24),
              const SizedBox(width: 12),
              Text(
                'Verification Evidence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add links to portfolios, certifications, or work samples (optional)',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: TextFormField(
                    controller: _evidenceController,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Add URL',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.link, color: Colors.blue[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue[400]!,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText:
                          'https://portfolio.com or https://github.com/...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.url,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _isSubmitting ? null : _addEvidence,
                  tooltip: 'Add Evidence',
                ),
              ),
            ],
          ),
          if (_evidenceLinks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Evidence Links (${_evidenceLinks.length}):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_evidenceLinks.length, (index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[400]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, color: Colors.blue[400], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _evidenceLinks[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeEvidence(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.greenAccent.withOpacity(0.3),
              ),
              child:
                  _isSubmitting
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.skill == null ? 'Posting...' : 'Updating...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        widget.skill == null
                            ? 'Post Skill 🚀'
                            : 'Update Skill ✨',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }
}
