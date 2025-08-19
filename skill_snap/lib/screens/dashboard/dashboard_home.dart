import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:skill_snap/screens/profile/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fl_chart/fl_chart.dart';
import 'activity_item.dart';
import '../../screens/skills/presentation/skill_list_screen.dart';
import '../../screens/skills/presentation/skill_post_screen.dart';
import '../../shared/provider/skill_stats_provider.dart';
import '../../screens/chat/match_requests_screen.dart';
import '../../services/superbase_service.dart';
import '../../screens/skills/data/activity_model.dart';
import '../skills/data/activity_repository.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_repository.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with SingleTickerProviderStateMixin {
  List<Activity> _activities = [];
  List<String> _userSkills = [];
  bool _isLoadingActivities = false;
  bool _isLoadingSkills = false;
  bool _isDisposed = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (_isDisposed) return;
    await Provider.of<SkillStatsProvider>(context, listen: false).loadStats();
    if (!mounted) return;
    await Future.wait([_loadActivities(), _loadUserSkills()]);
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;
    setState(() {
      _isLoadingActivities = true;
    });
    final userId = SupabaseService.client.auth.currentUser?.id ?? '';
    final result = await ActivityRepository().getRecentActivities(userId);
    if (!mounted) return;
    setState(() {
      _activities = result;
      _isLoadingActivities = false;
    });
  }

  Future<void> _loadUserSkills() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSkills = true;
    });
    final userId = SupabaseService.client.auth.currentUser?.id ?? '';
    final profileRepo = ProfileRepository();
    final profile = await profileRepo.getProfile(userId);
    if (!mounted) return;
    setState(() {
      _userSkills =
          (profile?['skills'] as List<dynamic>?)?.cast<String>() ?? [];
      _isLoadingSkills = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseService.client.auth.currentUser?.id ?? '';
    final userEmail = SupabaseService.client.auth.currentUser?.email ?? 'User';
    final greeting = _getGreeting();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black87, Colors.teal.shade900, Colors.blue.shade900],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadStats,
        color: Colors.teal.shade600,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                userEmail,
                greeting,
              ).animate().fadeIn(duration: 800.ms),
              const SizedBox(height: 20),
              _buildQuickActionsSection().animate().fadeIn(
                duration: 800.ms,
                delay: 200.ms,
              ),
              const SizedBox(height: 28),
              _buildFeaturedSkillsSection().animate().fadeIn(
                duration: 800.ms,
                delay: 300.ms,
              ),
              const SizedBox(height: 28),
              _buildRecentActivitySection(
                userId,
              ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
              const SizedBox(height: 28),
              _buildStatsSection().animate().fadeIn(
                duration: 800.ms,
                delay: 500.ms,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeader(BuildContext context, String userEmail, String greeting) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${userEmail.split('@')[0]}!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Your skill-sharing hub',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade300,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ProfileScreen(
                      userId: SupabaseService.client.auth.currentUser!.id,
                    ),
              ),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal.shade200, width: 2),
            ),
            child: Center(
              child: Icon(Icons.person, color: Colors.teal.shade600, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade300,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black87,
                Colors.teal.shade900,
                Colors.blue.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction(
                icon: Icons.add_circle_outline,
                label: 'Post',
                color: Colors.teal.shade600,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkillPostScreen(),
                      ),
                    ),
              ),
              _buildQuickAction(
                icon: Icons.search,
                label: 'Find',
                color: Colors.blue.shade600,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const SkillListScreen(
                              showOnlyUserSkills: false,
                            ),
                      ),
                    ),
              ),
              _buildQuickAction(
                icon: Icons.message,
                label: 'Chat',
                color: Colors.purple.shade600,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatListScreen()),
                    ),
              ),
              _buildQuickAction(
                icon: Icons.notifications,
                label: 'Requests',
                color: Colors.orange.shade600,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MatchRequestsScreen(),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder:
          (context, _) => Transform.translate(
            offset: Offset(0, _animation.value),
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Center(child: Icon(icon, size: 24, color: color)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFeaturedSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Your Skills',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade300,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildFeaturedSkillsList(),
      ],
    );
  }

  Widget _buildFeaturedSkillsList() {
    if (_isLoadingSkills) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    if (_userSkills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Add your first skill to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade300,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _userSkills
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade100, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.teal.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        skill,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildRecentActivitySection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade300,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 20, color: Colors.teal.shade600),
              onPressed: _loadStats,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRecentActivityList(),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    if (_isLoadingActivities) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      ).animate().fadeIn(duration: 400.ms);
    }
    if (_activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade300,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return ActivityItem(
          title: activity.title,
          subtitle: activity.subtitle,
          time: timeago.format(activity.time),
          icon: activity.icon,
          color: activity.color,
          onTap: () => _handleActivityTap(context, activity),
        ).animate().fadeIn(duration: 400.ms, delay: (100 * index).ms);
      },
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Your Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade300,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Consumer<SkillStatsProvider>(
          builder:
              (context, stats, _) => Card(
                elevation: 4,
                color: Colors.grey.shade900.withOpacity(0.8),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade200, width: 1),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            value:
                                '${(stats.offeredSkills / 100 * 100).toStringAsFixed(0)}%',
                            label: 'Offered',
                            icon: Icons.upload,
                            color: Colors.teal,
                          ),
                          _buildStatItem(
                            value:
                                '${(stats.requestedSkills / 100 * 100).toStringAsFixed(0)}%',
                            label: 'Requested',
                            icon: Icons.download,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            value:
                                '${(stats.messagesSent / 100 * 100).toStringAsFixed(0)}%',
                            label: 'Sent',
                            icon: Icons.send,
                            color: Colors.purple,
                          ),
                          _buildStatItem(
                            value:
                                '${(stats.messagesReceived / 100 * 100).toStringAsFixed(0)}%',
                            label: 'Received',
                            icon: Icons.inbox,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(8),
                        child: RadarChartWidget(
                          offeredSkills: stats.offeredSkills.toDouble(),
                          requestedSkills: stats.requestedSkills.toDouble(),
                          messagesSent: stats.messagesSent.toDouble(),
                          messagesReceived: stats.messagesReceived.toDouble(),
                          activeConnections: stats.activeConnections.toDouble(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
            ),
          ],
        ),
      ),
    );
  }

  void _handleActivityTap(BuildContext context, Activity activity) {
    if (activity.type == 'message' && activity.conversationId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                conversationId: activity.conversationId!,
                otherUserId:
                    activity.otherUserId ??
                    '00000000-0000-0000-0000-000000000000',
                otherUserName: activity.otherUserName ?? 'Unknown User',
                otherUserAvatar: activity.otherUserAvatar,
              ),
        ),
      );
    } else if (activity.type == 'match') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MatchRequestsScreen()),
      );
    }
  }
}

class RadarChartWidget extends StatelessWidget {
  final double offeredSkills;
  final double requestedSkills;
  final double messagesSent;
  final double messagesReceived;
  final double activeConnections;

  const RadarChartWidget({
    super.key,
    required this.offeredSkills,
    required this.requestedSkills,
    required this.messagesSent,
    required this.messagesReceived,
    required this.activeConnections,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      offeredSkills,
      requestedSkills,
      messagesSent,
      messagesReceived,
      activeConnections,
    ].reduce((a, b) => a > b ? a : b);
    final scale = maxValue > 0 ? 100 / maxValue : 1;

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        dataSets: [
          RadarDataSet(
            fillColor: Colors.teal.withOpacity(0.2),
            borderColor: Colors.teal.shade600,
            borderWidth: 2,
            dataEntries: [
              RadarEntry(value: offeredSkills * scale),
              RadarEntry(value: requestedSkills * scale),
              RadarEntry(value: messagesSent * scale),
              RadarEntry(value: messagesReceived * scale),
              RadarEntry(value: activeConnections * scale),
            ],
          ),
        ],
        radarBorderData: BorderSide(color: Colors.grey.shade300),
        gridBorderData: BorderSide(color: Colors.grey.shade200),
        titleTextStyle: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        getTitle: (index, angle) {
          switch (index) {
            case 0:
              return RadarChartTitle(text: 'Offered', angle: angle);
            case 1:
              return RadarChartTitle(text: 'Requested', angle: angle);
            case 2:
              return RadarChartTitle(text: 'Sent', angle: angle);
            case 3:
              return RadarChartTitle(text: 'Received', angle: angle);
            case 4:
              return RadarChartTitle(text: 'Connections', angle: angle);
            default:
              return RadarChartTitle(text: '');
          }
        },
        tickCount: 5,
        ticksTextStyle: TextStyle(color: Colors.grey.shade300, fontSize: 10),
        radarBackgroundColor: Colors.transparent,
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
      swapAnimationCurve: Curves.easeInOut,
    );
  }
}
