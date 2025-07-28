import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'profile_repository.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _profileController;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileRepository();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final userId = authController.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final profile = await _profileController.getProfile(userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });

        // Force refresh the image URL if it exists
        if (_profile?['profile_url'] != null) {
          final newUrl =
              '${_profile!['profile_url']}?${DateTime.now().millisecondsSinceEpoch}';
          setState(() {
            _profile!['profile_url'] = newUrl;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => EditProfileScreen(
                        profile: _profile,
                        onProfileUpdated: _loadProfile,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _profile?['profile_url'] != null
                        ? NetworkImage(_profile!['profile_url'])
                        : null,
                child:
                    _profile?['profile_url'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _profile?['full_name'] ?? 'No name provided',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            if (_profile?['bio'] != null) Text(_profile!['bio']),
            const SizedBox(height: 20),
            const Text(
              'My Skills:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children:
                  (_profile?['skills'] as List<dynamic>? ?? [])
                      .map((skill) => Chip(label: Text(skill.toString())))
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
