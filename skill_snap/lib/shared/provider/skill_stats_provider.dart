import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/superbase_service.dart';

class SkillStatsProvider with ChangeNotifier {
  int _offeredSkills = 0;
  int _activeMatches = 0;

  int get offeredSkills => _offeredSkills;
  int get activeMatches => _activeMatches;

  Future<void> loadStats() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get offered skills count
      final offeredResponse =
          await SupabaseService.client
              .from('skills')
              .select('*')
              .eq('user_id', userId)
              .eq('type', 'offer')
              .count();

      // Get active matches count
      final matchesResponse =
          await SupabaseService.client
              .from('matches')
              .select('*')
              .or('requester_id.eq.$userId,provider_id.eq.$userId')
              .eq('status', 'active')
              .count();

      // Update state with counts
      _offeredSkills = offeredResponse.count ?? 0;
      _activeMatches = matchesResponse.count ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stats: $e');
      _offeredSkills = 0;
      _activeMatches = 0;
      notifyListeners();
    }
  }
}
