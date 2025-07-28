import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'profile_repository.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  final List<String> _skills = [];
  late final TextEditingController _skillController;
  File? _profileImageFile;
  bool _isLoading = false; // Added loading state variable

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?['full_name']);
    _bioController = TextEditingController(text: widget.profile?['bio']);
    _skillController = TextEditingController();
    if (widget.profile?['skills'] != null) {
      _skills.addAll(
        (widget.profile!['skills'] as List<dynamic>).cast<String>(),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);

      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final userId = authController.currentUser?.id;
      final userEmail = authController.currentUser?.email; // Get user email

      if (userId == null || userEmail == null) {
        throw Exception('User not properly authenticated');
      }

      final profileController = ProfileRepository();

      String? profileUrl;
      if (_profileImageFile != null) {
        profileUrl = await profileController.uploadProfilePicture(
          userId,
          _profileImageFile!.path,
        );
      }

      await profileController.updateProfile(
        userId: userId,
        email: userEmail, // Pass the email
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        skills: _skills,
      );

      widget.onProfileUpdated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon:
                _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _profileImageFile != null
                            ? FileImage(_profileImageFile!)
                            : widget.profile?['profile_url'] != null
                            ? NetworkImage(widget.profile!['profile_url'])
                            : null,
                    child:
                        _profileImageFile == null &&
                                widget.profile?['profile_url'] == null
                            ? const Icon(Icons.camera_alt, size: 30)
                            : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        decoration: const InputDecoration(
                          labelText: 'Add Skill',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isLoading,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _isLoading ? null : _addSkill,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children:
                      _skills
                          .map(
                            (skill) => Chip(
                              label: Text(skill),
                              onDeleted:
                                  _isLoading ? null : () => _removeSkill(skill),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
