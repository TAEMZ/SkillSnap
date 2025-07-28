import 'package:supabase_flutter/supabase_flutter.dart';
import 'skill_model.dart';
import '../../../services/superbase_service.dart';
import './rating_model.dart';
import 'skill_match_model.dart';

class SkillRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // In SkillRepository
  Future<void> createSkillMatch({
    required String skillId,
    required String receiverId,
    required String message,
    String? offerSkillName, // Changed to nullable String?
  }) async {
    await _client.from('matches').insert({
      'skill_id': skillId,
      'provider_id': receiverId,
      'requester_id': _client.auth.currentUser!.id,
      'message': message,
      if (offerSkillName != null) 'offer_skill_name': offerSkillName,
      'status': 'pending',
    });
  }

  Future<List<SkillMatch>> getSkillMatches(String skillId) async {
    final response = await _client
        .from('matches')
        .select('''
        *,
        requester:users!requester_id(id, full_name, profile_url),
        offer_skill:skills!offer_skill_id(id, title)
      ''')
        .eq('skill_id', skillId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => SkillMatch.fromJson(json)).toList();
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    await _client.from('matches').update({'status': status}).eq('id', matchId);
  }

  Future<List<Skill>> fetchSkills({
    String? typeFilter,
    bool excludeCurrentUser = true,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      var query = _client
          .from('skills')
          .select('*, user:users(email, full_name, profile_url)');

      // Exclude current user's skills if requested
      if (excludeCurrentUser && userId != null) {
        query = query.neq('user_id', userId);
      }

      // Apply type filter if specified
      if (typeFilter != null && typeFilter.isNotEmpty) {
        query = query.eq('type', typeFilter);
      }

      // Execute the final query
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Skill.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch skills: $e');
    }
  }

  Future<List<Skill>> fetchUserSkills(String userId) async {
    try {
      final response = await _client
          .from('skills')
          .select('*, user:users!user_id(email, full_name, profile_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Add debug logging to inspect the response
      ('Supabase response: ${response.runtimeType} - $response');

      // Handle case where response might be a String (error message)
      if (response is String) {
        throw Exception('Supabase returned error: $response');
      }

      // Ensure response is a List before mapping
      if (response is! List) {
        throw Exception('Unexpected response format from Supabase');
      }

      return response.map((json) => Skill.fromJson(json)).toList();
    } catch (e) {
      ('Error fetching user skills: $e');
      throw Exception('Failed to fetch user skills: ${e.toString()}');
    }
  }

  Future<void> createSkill({
    required String title,
    required String type,
    String? description,
    List<String>? evidenceUrls,
    List<String>? exchangeSkills,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _client.from('skills').insert({
        'user_id': userId,
        'title': title,
        'type': type,
        if (description != null) 'description': description,
        if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
        if (exchangeSkills != null) 'exchange_skills': exchangeSkills,
      });
    } catch (e) {
      throw Exception('Failed to create skill: $e');
    }
  }

  Future<void> updateSkill({
    required String skillId,
    required String title,
    String? description,
    List<String>? evidenceUrls,
    List<String>? exchangeSkills,
  }) async {
    try {
      await _client
          .from('skills')
          .update({
            'title': title,
            if (description != null) 'description': description,
            if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
            if (exchangeSkills != null) 'exchange_skills': exchangeSkills,
          })
          .eq('id', skillId);
    } catch (e) {
      throw Exception('Failed to update skill: $e');
    }
  }

  Future<void> deleteSkill(String skillId) async {
    try {
      await _client.from('skills').delete().eq('id', skillId);
    } catch (e) {
      throw Exception('Failed to delete skill: $e');
    }
  }

  Future<List<Rating>> getSkillRatings(String skillId) async {
    try {
      final response = await _client
          .from('ratings')
          .select('''
          *,
          from_user_data:users!from_user(full_name, profile_url)
        ''')
          .eq('skill_id', skillId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Rating.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get skill ratings: $e');
    }
  }

  Future<void> addRating({
    required String skillId,
    required String toUser, // Changed from toUserId
    required int rating,
    String? feedback, // Changed from comment
  }) async {
    try {
      final fromUser = _client.auth.currentUser?.id;
      if (fromUser == null) throw Exception('User not logged in');

      await _client.from('ratings').insert({
        'skill_id': skillId,
        'from_user': fromUser, // Changed
        'to_user': toUser, // Changed
        'rating': rating,
        if (feedback != null) 'feedback': feedback, // Changed
      });
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  Stream<List<SkillMatch>> watchSkillMatches(String skillId) {
    return _client
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('skill_id', skillId)
        .order('created_at')
        .map((data) => data.map((json) => SkillMatch.fromJson(json)).toList());
  }

  // In skill_repository.dart
  Future<List<SkillMatch>> getPendingRequests(String userId) async {
    final response = await _client
        .from('matches')
        .select('''
        *,
        requester:users!requester_id(id, full_name, profile_url),
        skill:skills!skill_id(id, title)
      ''')
        .eq('provider_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((json) => SkillMatch.fromJson(json)).toList();
  }
}
