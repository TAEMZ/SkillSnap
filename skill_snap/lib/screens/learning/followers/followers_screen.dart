import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/superbase_service.dart';
import '../../../screens/profile/profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _followersFuture;
  late Future<List<Map<String, dynamic>>> _followingFuture;
  int _currentTabIndex = 0;
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

    _refreshData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _followersFuture = _getFollowers(userId);
      _followingFuture = _getFollowing(userId);
    });
  }

  Future<List<Map<String, dynamic>>> _getFollowers(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('followers')
          .select('''
          follower:users!follower_id(id, email, full_name, profile_url, bio, skills)
        ''')
          .eq('following_id', userId);

      return (response as List)
          .map((e) => e['follower'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load followers: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> _getFollowing(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('followers')
          .select('''
          following:users!following_id(id, email, full_name, profile_url, bio, skills)
        ''')
          .eq('follower_id', userId);

      return (response as List)
          .map((e) => e['following'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load following: ${e.toString()}');
    }
  }

  Future<void> _toggleFollow(
    BuildContext context,
    String targetUserId,
    bool isCurrentlyFollowing,
  ) async {
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      HapticFeedback.mediumImpact();

      if (isCurrentlyFollowing) {
        await SupabaseService.client
            .from('followers')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', targetUserId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.person_remove, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Unfollowed successfully'),
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
      } else {
        final existingFollow =
            await SupabaseService.client
                .from('followers')
                .select()
                .eq('follower_id', currentUserId)
                .eq('following_id', targetUserId)
                .maybeSingle();

        if (existingFollow == null) {
          await SupabaseService.client.from('followers').insert({
            'follower_id': currentUserId,
            'following_id': targetUserId,
            'created_at': DateTime.now().toIso8601String(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Followed successfully! 🎉'),
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('You are already following this user'),
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
      _refreshData();
    } catch (e) {
      if (e is PostgrestException && e.code == '23505') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                const Text('You are already following this user'),
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
      } else {
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
          slivers: [_buildAppBar(), _buildTabContent()],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return _currentTabIndex == 0
        ? _buildFollowersList()
        : _buildFollowingList();
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Network',
          style: TextStyle(
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentTabIndex = 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient:
                          _currentTabIndex == 0
                              ? LinearGradient(
                                colors: [
                                  Colors.greenAccent,
                                  Colors.green[600]!,
                                ],
                              )
                              : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          color:
                              _currentTabIndex == 0
                                  ? Colors.black
                                  : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Followers',
                          style: TextStyle(
                            color:
                                _currentTabIndex == 0
                                    ? Colors.black
                                    : Colors.grey[400],
                            fontWeight:
                                _currentTabIndex == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentTabIndex = 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient:
                          _currentTabIndex == 1
                              ? LinearGradient(
                                colors: [
                                  Colors.greenAccent,
                                  Colors.green[600]!,
                                ],
                              )
                              : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_alt,
                          color:
                              _currentTabIndex == 1
                                  ? Colors.black
                                  : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Following',
                          style: TextStyle(
                            color:
                                _currentTabIndex == 1
                                    ? Colors.black
                                    : Colors.grey[400],
                            fontWeight:
                                _currentTabIndex == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowersList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _followersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              'No Followers Yet',
              'Share your skills to attract followers!',
              Icons.group_off,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final user = snapshot.data![index];
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
                child: _buildUserCard(context, user, false),
              ),
            );
          }, childCount: snapshot.data!.length),
        );
      },
    );
  }

  Widget _buildFollowingList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _followingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              'Not Following Anyone',
              'Discover interesting people to follow!',
              Icons.person_search,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final user = snapshot.data![index];
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
                child: _buildUserCard(context, user, true),
              ),
            );
          }, childCount: snapshot.data!.length),
        );
      },
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
                'Something went wrong',
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
                  _refreshData();
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
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
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),
                      child: Icon(icon, color: Colors.greenAccent, size: 64),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> user,
    bool isFollowing,
  ) {
    final skills = (user['skills'] as List<dynamic>? ?? []).cast<String>();
    final isCurrentUser =
        user['id'] == SupabaseService.client.auth.currentUser?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: user['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey[700],
                        backgroundImage:
                            user['profile_url'] != null
                                ? NetworkImage(user['profile_url'] as String)
                                : null,
                        child:
                            user['profile_url'] == null
                                ? Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.greenAccent,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['full_name'] ?? 'Anonymous',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isCurrentUser)
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isFollowing
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.greenAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isFollowing ? Colors.red : Colors.greenAccent,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap:
                                () => _toggleFollow(
                                  context,
                                  user['id'] as String,
                                  isFollowing,
                                ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFollowing
                                        ? Icons.person_remove
                                        : Icons.person_add,
                                    color:
                                        isFollowing
                                            ? Colors.red
                                            : Colors.greenAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isFollowing ? 'Unfollow' : 'Follow',
                                    style: TextStyle(
                                      color:
                                          isFollowing
                                              ? Colors.red
                                              : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (user['bio'] != null &&
                    (user['bio'] as String).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['bio'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Skills:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        skills
                            .take(5)
                            .map(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.greenAccent),
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  if (skills.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${skills.length - 5} more skills',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
