import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'stats_card.dart';
import 'activity_item.dart';
import 'dashboard_card.dart';
import '../../screens/skills/presentation/skill_list_screen.dart';
import '../../screens/skills/presentation/skill_post_screen.dart';
import '../../shared/provider/skill_stats_provider.dart';
import '../../screens/chat/messages_screen.dart';
import '../../screens/chat/match_requests_screen.dart';
import '../../services/superbase_service.dart';
import '../../screens/skills/data/activity_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../skills/data/activity_repository.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_list_screen.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  List<Activity> _activities = [];
  bool _isLoadingActivities = false;
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await Provider.of<SkillStatsProvider>(context, listen: false).loadStats();
    await _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    final userId = SupabaseService.client.auth.currentUser?.id ?? '';
    final result = await ActivityRepository().getRecentActivities(userId);

    setState(() {
      _activities = result;
      _isLoadingActivities = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseService.client.auth.currentUser?.id ?? '';

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to SkillSnap 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'What would you like to do today?',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // Stats Cards with refresh button
            Row(
              children: [
                const Text(
                  'Your Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadStats,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Consumer<SkillStatsProvider>(
              builder:
                  (context, stats, _) => Row(
                    children: [
                      StatsCard(
                        value: stats.offeredSkills.toString(),
                        label: 'Skills Offered',
                        icon: Icons.work_outline,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 15),
                      StatsCard(
                        value: stats.activeMatches.toString(),
                        label: 'Connections',
                        icon: Icons.people_outline,
                        color: Colors.green,
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 30),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            _buildRecentActivity(userId),
            const SizedBox(height: 10),

            // Quick Actions Grid
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                DashboardCard(
                  icon: Icons.add_circle_outline,
                  title: 'Post Skill',
                  color: Colors.teal,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SkillPostScreen(),
                        ),
                      ),
                ),
                DashboardCard(
                  icon: Icons.search,
                  title: 'Find Skills',
                  color: Colors.orange,
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
                DashboardCard(
                  icon: Icons.message,
                  title: 'Messages',
                  color: Colors.purple,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatListScreen()),
                      ),
                ),
                DashboardCard(
                  icon: Icons.notifications,
                  title: 'Requests',
                  color: Colors.red,
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
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(String userId) {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activities.isEmpty) {
      return const Text('No recent activity');
    }
    return Column(
      children:
          _activities.map((activity) {
            return ActivityItem(
              title: activity.title,
              subtitle: activity.subtitle,
              time: timeago.format(activity.time),
              icon: activity.icon,
              color: activity.color,
              onTap: () => _handleActivityTap(context, activity),
            );
          }).toList(),
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
