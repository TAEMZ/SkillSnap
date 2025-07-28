import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    return response;
  }

  Future<void> updateProfile({
    required String userId,
    required String email,
    String? fullName,
    String? bio,
    List<String>? skills,
    String? profileUrl, // Add profileUrl parameter
  }) async {
    await _client.from('users').upsert({
      'id': userId,
      'email': email,
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (skills != null) 'skills': skills,
      if (profileUrl != null) 'profile_url': profileUrl,
    });
  }

  Future<String> uploadProfilePicture(String userId, String filePath) async {
    try {
      final fileExt = filePath.split('.').last;
      final fileName = '$userId.$fileExt';
      final file = File(filePath);

      // Upload the file
      await _client.storage
          .from('profile-pictures')
          .upload(
            fileName,
            file,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true, // Overwrite if exists
            ),
          );

      // Get the permanent public URL
      final publicUrl = _client.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      // Update the user's profile_url in the database
      await _client
          .from('users')
          .update({'profile_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: ${e.toString()}');
    }
  }
}
