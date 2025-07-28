import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import 'sidebar.dart';
import 'dashboard_home.dart';
import '../profile/profile_screen.dart';
import '../skills/presentation/skill_list_screen.dart'; // Add this
import '../skills/presentation/my_skills_screen.dart';
import '../chat/message_provider.dart'; // Add this

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final messageProvider = Provider.of<MessageProvider>(
        context,
        listen: false,
      );

      auth.loadProfile().then((_) {
        if (auth.currentProfile?['profile_url'] != null) {
          auth.updateProfileImage(auth.currentProfile!['profile_url']);
        }
      });

      messageProvider.loadUnreadCount(); // Load message counts
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardHome();
      case 1:
        return Consumer<AuthController>(
          builder:
              (context, auth, _) => ProfileScreen(userId: auth.currentUser?.id),
        );
      case 2:
      case 2:
        return const SkillListScreen(
          showOnlyUserSkills: false,
        ); // Changed parameter // Modified
      case 3:
        return const Center(child: Text('Messages Screen'));
      case 4:
        return const Center(child: Text('Ratings Screen'));
      case 5:
        return const MySkillsScreen(); // New case
      default:
        return const DashboardHome();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthController>(context, listen: false);

    // Show loading indicator

    final success = await auth.signOut();
    scaffold.hideCurrentSnackBar();

    if (success && mounted) {
      // Navigate to login and clear stack
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
      drawer: Consumer<AuthController>(
        builder: (context, auth, child) {
          return SkillSnapSidebar(
            selectedIndex: _selectedIndex,
            scaffoldKey: _scaffoldKey,
            onItemTapped: _onItemTapped,
            onLogout: () => _logout(context), // Now returns Future<void>
            profileData: auth.currentProfile,
          );
        },
      ),
      appBar: AppBar(
        title: const Text(
          'SkillSnap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.teal),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.teal),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE0F7FA)],
          ),
        ),
        child: _getCurrentScreen(),
      ),
    );
  }
}
