import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SkillListScreenState extends State<SkillListScreen>
    with TickerProviderStateMixin {
  final SkillRepository _repository = SkillRepository();
  late Future<List<Skill>> _skillsFuture;
  String? _typeFilter;
  String? _userId;
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _userId = SupabaseService.client.auth.currentUser?.id;

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

    _refreshSkills();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshSkills() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      if (widget.showOnlyUserSkills && _userId != null) {
        _skillsFuture = _repository.fetchUserSkills(_userId!);
      } else {
        _skillsFuture = _repository.fetchSkills(
          typeFilter: _typeFilter,
          excludeCurrentUser: !widget.showOnlyUserSkills,
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
                Expanded(child: Text('Error loading skills: $e')),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSkill(
    BuildContext context,
    String skillId,
    int index,
    List<Skill> skills,
  ) async {
    try {
      HapticFeedback.mediumImpact();
      setState(() => _isLoading = true);
      await _repository.deleteSkill(skillId);
      if (mounted) {
        setState(() {
          skills.removeAt(index);
          _skillsFuture = Future.value(skills);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Skill deleted successfully'),
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
                Expanded(child: Text('Error deleting skill: $e')),
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
        await _refreshSkills();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [_buildAppBar(), _buildContent()],
      ),
      floatingActionButton: widget.showOnlyUserSkills ? _buildFAB() : null,
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
          widget.showOnlyUserSkills ? 'My Skills' : 'Skills Marketplace',
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
      actions: [
        if (widget.showOnlyUserSkills)
          IconButton(
            icon: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Icon(Icons.refresh, color: Colors.white),
                );
              },
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _refreshSkills();
            },
            tooltip: 'Refresh Skills',
          )
        else
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showFilterDialog(context);
            },
            tooltip: 'Filter Skills',
          ),
      ],
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<Skill>>(
      future: _skillsFuture,
      builder: (context, snapshot) {
        if (_isLoading) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading skills...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        return _buildSkillList(snapshot.data!);
      },
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey[900],
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_outline, color: Colors.grey[400], size: 80),
              const SizedBox(height: 24),
              Text(
                widget.showOnlyUserSkills
                    ? 'No skills posted yet'
                    : 'No skills found',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.showOnlyUserSkills
                    ? 'Tap the + button to add your first skill'
                    : 'Try adjusting your filters or check back later',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red[900]!.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red[400]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 64),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _refreshSkills();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillList(List<Skill> skills) {
    if (skills.isEmpty) {
      return SliverFillRemaining(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[900],
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, color: Colors.grey[400], size: 80),
                  const SizedBox(height: 24),
                  Text(
                    widget.showOnlyUserSkills
                        ? 'No skills posted yet'
                        : 'No skills found',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.showOnlyUserSkills
                        ? 'Tap the + button to add your first skill'
                        : 'Try adjusting your filters or check back later',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final skill = skills[index];
        final isOwnSkill = skill.userId == _userId;

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.3 + (index * 0.1)),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(index * 0.1, 1.0, curve: Curves.elasticOut),
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dismissible(
              key: Key(skill.id),
              direction:
                  isOwnSkill
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
              confirmDismiss:
                  isOwnSkill
                      ? (direction) async {
                        HapticFeedback.heavyImpact();
                        return await _showDeleteConfirmation(context);
                      }
                      : null,
              onDismissed:
                  isOwnSkill
                      ? (direction) async {
                        await _deleteSkill(context, skill.id, index, skills);
                      }
                      : null,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete, color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SkillCard(
                  skill: skill,
                  isClickable: true,
                  onTap: () => _showSkillDetails(context, skill),
                  showActions: false,
                ),
              ),
            ),
          ),
        );
      }, childCount: skills.length),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SkillPostScreen()),
              ).then((_) => _refreshSkills());
            },
            icon: const Icon(Icons.add, size: 24),
            label: const Text(
              'Add Skill',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[400]),
                const SizedBox(width: 12),
                const Text(
                  'Confirm Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to delete this skill? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.greenAccent),
                const SizedBox(width: 12),
                const Text(
                  'Filter Skills',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterOption('All Skills', null),
                _buildFilterOption('Offers Only', 'offer'),
                _buildFilterOption('Requests Only', 'request'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildFilterOption(String title, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color:
            _typeFilter == value
                ? Colors.greenAccent.withOpacity(0.2)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _typeFilter == value ? Colors.greenAccent : Colors.grey[600]!,
        ),
      ),
      child: RadioListTile<String?>(
        value: value,
        groupValue: _typeFilter,
        title: Text(
          title,
          style: TextStyle(
            color: _typeFilter == value ? Colors.greenAccent : Colors.white70,
            fontWeight:
                _typeFilter == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onChanged: (newValue) => _updateFilter(newValue),
        activeColor: Colors.greenAccent,
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
