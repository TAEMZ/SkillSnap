import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:provider/provider.dart';
import '../screens/skills/presentation/skill_post_screen.dart';
import '../screens/dashboard/dashboard_home.dart';
import '../screens/auth/auth_controller.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/sidebar.dart';
import '../screens/learning/learning_hub_screen.dart';
import '../screens/learning/sparks/spark_screen.dart';
import '../screens/learning/gems_screen.dart';
import '../screens/learning/followers/followers_screen.dart';

class PersistentNavigation extends StatefulWidget {
  const PersistentNavigation({super.key});

  @override
  State<PersistentNavigation> createState() => _PersistentNavigationState();
}

class _PersistentNavigationState extends State<PersistentNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Updated pages for new navigation structure
  final List<Widget> _pages = [
    const DashboardHome(), // Home
    const LearningHubScreen(),
    const SparksScreen(),
    const GemsScreen(),
    const FollowersScreen(),
  ];

  Future<void> _logout(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthController>(context, listen: false);

    scaffold.showSnackBar(const SnackBar(content: Text('Logging out...')));

    final success = await auth.signOut();
    scaffold.hideCurrentSnackBar();

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else if (mounted) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
      ),
      drawer: SkillSnapSidebar(
        selectedIndex: _selectedIndex,
        scaffoldKey: _scaffoldKey,
        onItemTapped: (index) {
          // Sidebar navigation remains independent
          _scaffoldKey.currentState?.closeDrawer();
        },
        onLogout: () => _logout(context),
        profileData: Provider.of<AuthController>(context).currentProfile,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildConvexAppBar(),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkillPostScreen(),
                      ),
                    ),
                backgroundColor: Colors.teal.shade600,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
    );
  }

  Widget _buildConvexAppBar() {
    return ConvexAppBar(
      style: TabStyle.reactCircle, // Changed from fixedCircle to reactCircle
      backgroundColor: const Color.fromARGB(255, 163, 214, 155),
      color: const Color.fromARGB(255, 58, 44, 44),
      activeColor: const Color.fromARGB(255, 8, 12, 12),
      items: const [
        TabItem(icon: Icons.home, title: 'Home'),
        TabItem(icon: Icons.school, title: 'Learn'),
        TabItem(icon: Icons.bolt, title: 'Sparks'),
        TabItem(icon: Icons.diamond, title: 'Gems'),
        TabItem(icon: Icons.people, title: "Followers"),
      ],
      initialActiveIndex: _selectedIndex,
      onTap: (int index) => setState(() => _selectedIndex = index),
      curveSize: 100,
      top: -20,
    );
  }
}
