import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/superbase_service.dart';
import '../data/skill_model.dart';
import './skill_details_screen.dart';

class SkillCard extends StatefulWidget {
  final Skill skill;
  final bool showActions;
  final bool isClickable;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onFollowChanged;

  const SkillCard({
    super.key,
    required this.skill,
    this.showActions = false,
    this.isClickable = true,
    this.onDelete,
    this.onTap,
    this.onFollowChanged,
  });

  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFollowStatus() async {
    if (widget.skill.userId == SupabaseService.client.auth.currentUser?.id) {
      return; // Don't check follow status for own skills
    }

    final isFollowing = await _isFollowingUser(widget.skill.userId);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  Future<bool> _isFollowingUser(String userId) async {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      final response =
          await SupabaseService.client
              .from('followers')
              .select()
              .eq('follower_id', currentUserId)
              .eq('following_id', userId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    setState(() {
      _isLoadingFollow = true;
    });

    try {
      HapticFeedback.lightImpact();

      if (_isFollowing) {
        await SupabaseService.client
            .from('followers')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.skill.userId);
      } else {
        await SupabaseService.client.from('followers').insert({
          'follower_id': currentUserId,
          'following_id': widget.skill.userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (widget.onFollowChanged != null) {
        widget.onFollowChanged!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
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
      if (mounted) {
        setState(() {
          _isLoadingFollow = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRequest = widget.skill.type == 'request';
    final isOwnSkill =
        widget.skill.userId == SupabaseService.client.auth.currentUser?.id;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[850]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isRequest
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.greenAccent.withOpacity(0.3),
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap:
                    widget.isClickable
                        ? () {
                          HapticFeedback.lightImpact();
                          _animationController.forward().then((_) {
                            _animationController.reverse();
                          });

                          if (widget.onTap != null) {
                            widget.onTap!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        SkillDetailScreen(skill: widget.skill),
                              ),
                            );
                          }
                        }
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const SizedBox(height: 12),
                      _buildDescription(),
                      if (isRequest &&
                          widget.skill.exchangeSkills?.isNotEmpty == true)
                        _buildExchangeSkills(),
                      const SizedBox(height: 20),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final isRequest = widget.skill.type == 'request';
    final isOwnSkill =
        widget.skill.userId == SupabaseService.client.auth.currentUser?.id;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isRequest
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.greenAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRequest ? Colors.orange : Colors.greenAccent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRequest ? Icons.help_outline : Icons.star,
                color: isRequest ? Colors.orange : Colors.greenAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isRequest ? 'REQUEST' : 'OFFER',
                style: TextStyle(
                  color: isRequest ? Colors.orange : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (widget.showActions && isOwnSkill)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: widget.onDelete,
            tooltip: 'Delete Skill',
          )
        else if (!isOwnSkill)
          _buildFollowButton(),
      ],
    );
  }

  Widget _buildFollowButton() {
    return Container(
      decoration: BoxDecoration(
        color:
            _isFollowing
                ? Colors.red.withOpacity(0.1)
                : Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFollowing ? Colors.red : Colors.greenAccent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isLoadingFollow ? null : _toggleFollow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingFollow)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isFollowing ? Colors.red : Colors.greenAccent,
                      ),
                    ),
                  )
                else
                  Icon(
                    _isFollowing ? Icons.person_remove : Icons.person_add,
                    size: 16,
                    color: _isFollowing ? Colors.red : Colors.greenAccent,
                  ),
                const SizedBox(width: 6),
                Text(
                  _isFollowing ? 'Unfollow' : 'Follow',
                  style: TextStyle(
                    color: _isFollowing ? Colors.red : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.skill.title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    if (widget.skill.description == null) return const SizedBox.shrink();

    return Text(
      widget.skill.description!,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
    );
  }

  Widget _buildExchangeSkills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Offering in exchange:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children:
              widget.skill.exchangeSkills!
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[700],
            backgroundImage:
                widget.skill.userAvatar != null
                    ? NetworkImage(widget.skill.userAvatar!)
                    : null,
            child:
                widget.skill.userAvatar == null
                    ? const Icon(Icons.person, size: 20, color: Colors.white70)
                    : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.skill.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.skill.userEmail,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: Text(
            '${widget.skill.createdAt.day}/${widget.skill.createdAt.month}/${widget.skill.createdAt.year}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
