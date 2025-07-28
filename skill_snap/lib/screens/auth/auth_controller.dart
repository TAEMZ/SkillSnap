import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Map<String, dynamic>? _currentProfile;
  Map<String, dynamic>? get currentProfile => _currentProfile;

  Future<void> loadProfile() async {
    if (currentUser == null) return;

    final response =
        await _client
            .from('users')
            .select()
            .eq('id', currentUser!.id)
            .maybeSingle();

    _currentProfile = response;
    notifyListeners();
  }

  Future<void> updateProfileImage(String url) async {
    if (_currentProfile != null) {
      _currentProfile!['profile_url'] =
          '$url?${DateTime.now().millisecondsSinceEpoch}';
      notifyListeners();
    }
  }

  Future<void> initializeProfile() async {
    if (currentUser == null) return;

    final existing =
        await _client
            .from('users')
            .select()
            .eq('id', currentUser!.id)
            .maybeSingle();

    if (existing == null) {
      await _client.from('users').upsert({
        'id': currentUser!.id,
        'email': currentUser!.email,
      });
    }

    await loadProfile();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return res.user != null ? null : 'Unknown login error';
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Login failed. Try again.';
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      notifyListeners();

      if (res.user == null) return 'User is null after signup.';

      await Future.delayed(const Duration(seconds: 1));

      final insertResponse =
          await _client
              .from('users')
              .insert({'id': res.user!.id, 'email': email, 'device_id': null})
              .select()
              .maybeSingle();

      if (insertResponse == null) return 'Failed to insert user data.';

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Signup failed: $e';
    }
  }

  Future<bool> signOut() async {
    try {
      await _client.auth.signOut();
      _currentProfile = null;
      notifyListeners();
      return true; // Success
    } catch (e) {
      debugPrint('Logout error: $e');
      return false; // Failure
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to send reset email.';
    }
  }

  bool isLoggedIn() {
    return _client.auth.currentUser != null;
  }
}
