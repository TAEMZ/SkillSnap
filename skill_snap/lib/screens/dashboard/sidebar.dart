import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/message_provider.dart';
import '../chat/chat_list_screen.dart';
import '../chat/match_requests_screen.dart';
import '../skills/presentation/skill_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../shared/provider/theme_provider.dart';
import '../../services/superbase_service.dart';

class SkillSnapSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Future<void> Function() onLogout;
  final Map<String, dynamic>? profileData;
  final int unreadMessageCount;
  final int pendingRequestCount;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SkillSnapSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onLogout,
    required this.profileData,
    required this.scaffoldKey,
    this.unreadMessageCount = 0,
    this.pendingRequestCount = 0,
  });

  @override
  State<SkillSnapSidebar> createState() => _SkillSnapSidebarState();
}

class _SkillSnapSidebarState extends State<SkillSnapSidebar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(-0.3, 0),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = Provider.of<MessageProvider>(context).unreadCount;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final imageUrl =
        widget.profileData?['profile_url'] != null
            ? '${widget.profileData!['profile_url']}?${DateTime.now().millisecondsSinceEpoch}'
            : null;

    return Drawer(
      backgroundColor: Colors.black,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.grey, Colors.white12],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildHeader(context, imageUrl),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        context,
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        index: 0,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.person,
                        title: 'My Profile',
                        index: 1,
                        destination: ProfileScreen(
                          userId: SupabaseService.client.auth.currentUser?.id,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.work_outline,
                        title: 'Skills Market',
                        index: 2,
                        destination: const SkillListScreen(
                          showOnlyUserSkills: false,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.currency_exchange,
                        title: 'Requests',
                        index: 3,
                        badgeCount: widget.pendingRequestCount,
                        destination: const MatchRequestsScreen(),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.list_alt,
                        title: 'My Skills',
                        index: 4,
                        destination: const SkillListScreen(
                          showOnlyUserSkills: true,
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.message,
                        title: 'Messages',
                        index: 5,
                        badgeCount: unreadCount,
                        destination: const ChatListScreen(),
                      ),
                    ],
                  ),
                ),
                _buildFooter(context, themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? imageUrl) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[700]!, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
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
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    child:
                        imageUrl == null
                            ? Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.greenAccent,
                            )
                            : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profileData?['full_name'] ?? 'Welcome back!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.profileData?['email'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.profileData?['email'] ?? '',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Container(
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
                    'Active',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
    int badgeCount = 0,
    Widget? destination,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient:
            isSelected
                ? LinearGradient(
                  colors: [
                    Colors.greenAccent.withOpacity(0.2),
                    Colors.green.withOpacity(0.2),
                  ],
                )
                : null,
        border:
            isSelected ? Border.all(color: Colors.greenAccent, width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);

            if (destination != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            } else {
              widget.onItemTapped(index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -8, end: -8),
                  badgeContent: Text(
                    badgeCount > 0 ? badgeCount.toString() : '',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  showBadge: badgeCount > 0,
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: Colors.red[600]!,
                    elevation: 4,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.greenAccent.withOpacity(0.2)
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.greenAccent : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.greenAccent : Colors.grey[300],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1)),
      ),
      child: Column(
        children: [
          // Theme toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          themeProvider.toggleTheme(value);
                        },
                        activeColor: Colors.greenAccent,
                        inactiveThumbColor: Colors.grey[400],
                        inactiveTrackColor: Colors.grey[700],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[800]!, Colors.red[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final scaffold = ScaffoldMessenger.of(context);
                  try {
                    await widget.onLogout();
                    scaffold.hideCurrentSnackBar();
                  } catch (e) {
                    scaffold.hideCurrentSnackBar();
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Logout failed: ${e.toString()}'),
                            ),
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
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
