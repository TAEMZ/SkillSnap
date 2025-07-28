import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_repository.dart';

class ProfileController {
  final ProfileRepository _repository = ProfileRepository();
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile(String userId) {
    return _repository.getProfile(userId);
  }

  Future<void> updateProfile({
    required String userId,
    required String email, // Added required email parameter
    String? fullName,
    String? bio,
    List<String>? skills,
  }) async {
    // Get current user email if not provided
    final userEmail =
        email.isNotEmpty ? email : _client.auth.currentUser?.email;

    if (userEmail == null) {
      throw Exception('User email is required');
    }

    return _repository.updateProfile(
      userId: userId,
      email: userEmail, // Pass the email
      fullName: fullName,
      bio: bio,
      skills: skills,
    );
  }

  Future<String> uploadProfilePicture(String userId, String filePath) {
    return _repository.uploadProfilePicture(userId, filePath);
  }
}
