import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'package:badges/badges.dart' as badges;
import '../chat/message_provider.dart';
import '../chat/chat_screen.dart';
import '../skills/data/conversation_model.dart';
import '../chat/chat_list_screen.dart';

class SkillSnapSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final unreadCount = Provider.of<MessageProvider>(context).unreadCount;
    final imageUrl =
        profileData?['profile_url'] != null
            ? '${profileData!['profile_url']}?${DateTime.now().millisecondsSinceEpoch}'
            : null;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00796B), Color(0xFF004D40)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF00695C)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        imageUrl != null
                            ? NetworkImage(imageUrl) as ImageProvider
                            : null,
                    backgroundColor: Colors.white,
                    child:
                        imageUrl == null
                            ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.teal,
                            )
                            : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profileData?['full_name'] ?? 'Welcome back!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profileData?['email'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        profileData?['email'] ?? '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
            _buildMenuItem(icon: Icons.dashboard, title: 'Dashboard', index: 0),
            _buildMenuItem(icon: Icons.person, title: 'My Profile', index: 1),
            _buildMenuItem(
              icon: Icons.work_outline,
              title: 'Skills Market',
              index: 2,
            ),
            _buildMenuItem(icon: Icons.list_alt, title: 'My Skills', index: 5),
            // Inside your ListView children:
            ListTile(
              leading: const Icon(Icons.message, color: Colors.white),
              title: const Text(
                'Messages',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatListScreen(), // A new screen
                  ),
                );
              },
            ),

            const Divider(color: Colors.white54),
            _buildLogoutItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: badges.Badge(
        badgeContent: Text(
          badgeCount > 0 ? badgeCount.toString() : '',
          style: const TextStyle(color: Colors.white),
        ),
        showBadge: badgeCount > 0,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      selected: selectedIndex == index,
      selectedTileColor: Colors.teal.shade700.withOpacity(0.3),
      onTap: () => onItemTapped(index),
    );
  }

  Widget _buildLogoutItem() {
    return Builder(
      builder: (context) {
        return ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          onTap: () async {
            final scaffold = ScaffoldMessenger.of(context);

            // Show loading indicator

            try {
              await onLogout();
              scaffold.hideCurrentSnackBar();
            } catch (e) {
              scaffold.hideCurrentSnackBar();
              scaffold.showSnackBar(
                SnackBar(content: Text('Logout failed: ${e.toString()}')),
              );
            }
          },
        );
      },
    );
  }
}
