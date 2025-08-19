import '../../services/superbase_service.dart';
import 'package:flutter/foundation.dart';

class SkillStatsProvider with ChangeNotifier {
  int _offeredSkills = 0;
  int _requestedSkills = 0;
  int _activeConnections = 0;
  int _messagesSent = 0;
  int _pendingRequests = 0;
  int _messagesReceived = 0;
  int _uniqueUsersContacted = 0;

  int get offeredSkills => _offeredSkills;
  int get requestedSkills => _requestedSkills;
  int get activeConnections => _activeConnections;
  int get messagesSent => _messagesSent;
  int get pendingRequests => _pendingRequests;
  int get messagesReceived => _messagesReceived;
  int get uniqueUsersContacted => _uniqueUsersContacted;

  Future<int> _getMessagesReceivedCount(String userId) async {
    final response =
        await SupabaseService.client
            .from('messages')
            .select('*')
            .eq('receiver_id', userId)
            .count();
    return response.count ?? 0;
  }

  Future<int> _getUniqueUsersContacted(String userId) async {
    final response = await SupabaseService.client
        .from('messages')
        .select('sender_id')
        .eq('receiver_id', userId)
        .neq('sender_id', userId);
    return response.length;
  }

  Future<void> loadStats() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get all stats in parallel
      final results = await Future.wait([
        _getOfferedSkillsCount(userId),
        _getRequestedSkillsCount(userId),
        _getActiveConnectionsCount(userId),
        _getMessagesSentCount(userId),
        _getPendingRequestsCount(userId),
        _getMessagesReceivedCount(userId),
        _getUniqueUsersContacted(userId),
      ]);

      // Update state
      _offeredSkills = results[0];
      _requestedSkills = results[1];
      _activeConnections = results[2];
      _messagesSent = results[3];
      _pendingRequests = results[4];
      _messagesReceived = results[5];
      _uniqueUsersContacted = results[6];

      notifyListeners();
    } catch (e) {
      print('Error loading stats: $e');
      // Reset all stats on error
      _offeredSkills = 0;
      _requestedSkills = 0;
      _activeConnections = 0;
      _messagesSent = 0;
      _pendingRequests = 0;
      _messagesReceived = 0;
      _uniqueUsersContacted = 0;
      notifyListeners();
    }
  }

  Future<int> _getOfferedSkillsCount(String userId) async {
    final response =
        await SupabaseService.client
            .from('skills')
            .select('*')
            .eq('user_id', userId)
            .eq('type', 'offer')
            .count();
    return response.count ?? 0;
  }

  Future<int> _getRequestedSkillsCount(String userId) async {
    final response =
        await SupabaseService.client
            .from('skills')
            .select('*')
            .eq('user_id', userId)
            .eq('type', 'request')
            .count();
    return response.count ?? 0;
  }

  Future<int> _getActiveConnectionsCount(String userId) async {
    final response =
        await SupabaseService.client
            .from('matches')
            .select('*')
            .or('requester_id.eq.$userId,provider_id.eq.$userId')
            .eq('status', 'active')
            .count();
    return response.count ?? 0;
  }

  Future<int> _getMessagesSentCount(String userId) async {
    final response =
        await SupabaseService.client
            .from('messages')
            .select('*')
            .eq('sender_id', userId)
            .count();
    return response.count ?? 0;
  }

  Future<int> _getPendingRequestsCount(String userId) async {
    final response =
        await SupabaseService.client
            .from('matches')
            .select('*')
            .eq('provider_id', userId)
            .eq('status', 'pending')
            .count();
    return response.count ?? 0;
  }
}
