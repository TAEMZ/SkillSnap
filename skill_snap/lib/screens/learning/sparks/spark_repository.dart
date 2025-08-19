import 'package:supabase_flutter/supabase_flutter.dart';
import '../sparks/sparks_model.dart';
import '../../../services/spark_service.dart';

class SparkRepository {
  final SupabaseClient _client;
  final GeminiService _geminiService;

  SparkRepository({
    required SupabaseClient client,
    required GeminiService geminiService,
  }) : _client = client,
       _geminiService = geminiService;

  Future<List<Spark>> getDailySparks({required String userId}) async {
    // First check if user has any uncompleted sparks
    final existingSparks = await _getUncompletedSparks(userId);
    if (existingSparks.isNotEmpty) {
      return existingSparks;
    }

    // If no existing sparks, generate new ones
    return await _generateNewSparks(userId);
  }

  Future<List<Spark>> _getUncompletedSparks(String userId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final response = await _client
        .from('user_sparks')
        .select('spark_id')
        .eq('user_id', userId)
        .eq('completed_date', today);

    final completedIds =
        (response as List).map((e) => e['spark_id'] as String).toList();

    if (completedIds.length >= 3) {
      return []; // User has completed all sparks for today
    }

    final sparksResponse = await _client
        .from('sparks')
        .select()
        .not('id', 'in', completedIds)
        .limit(3 - completedIds.length)
        .order('created_at', ascending: false);

    return (sparksResponse as List)
        .map((json) => Spark.fromJson(json))
        .toList();
  }

  Future<List<Spark>> _generateNewSparks(String userId) async {
    // Get user skills from profile
    final profileResponse =
        await _client.from('users').select('skills').eq('id', userId).single();

    final skills = (profileResponse['skills'] as List?)?.cast<String>() ?? [];

    // Generate sparks using Gemini
    final generatedSparks = await _geminiService.generateSparks(
      userSkills: skills,
    );

    // Save to database and return
    final List<Spark> sparks = [];
    for (final sparkData in generatedSparks) {
      final response =
          await _client.from('sparks').insert(sparkData).select().single();

      sparks.add(Spark.fromJson(response));
    }

    return sparks;
  }

  Future<void> completeSpark({required String sparkId, String? notes}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('user_sparks').insert({
      'user_id': userId,
      'spark_id': sparkId,
      'notes': notes,
    });

    // Update streak
    await _updateUserStreak(userId);
  }

  Future<void> _updateUserStreak(String userId) async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Get current streak info
    final streakResponse =
        await _client
            .from('user_streaks')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    if (streakResponse == null) {
      // First completion
      await _client.from('user_streaks').insert({
        'user_id': userId,
        'current_streak': 1,
        'longest_streak': 1,
        'last_completed_date': today.toIso8601String(),
      });
    } else {
      final lastDate = DateTime.parse(streakResponse['last_completed_date']);
      final currentStreak = streakResponse['current_streak'] as int;
      final longestStreak = streakResponse['longest_streak'] as int;

      if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        // Consecutive day
        final newStreak = currentStreak + 1;
        await _client
            .from('user_streaks')
            .update({
              'current_streak': newStreak,
              'longest_streak':
                  newStreak > longestStreak ? newStreak : longestStreak,
              'last_completed_date': today.toIso8601String(),
            })
            .eq('user_id', userId);
      } else if (lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {
        // Already completed today
        return;
      } else {
        // Broken streak - reset to 1
        await _client
            .from('user_streaks')
            .update({
              'current_streak': 1,
              'last_completed_date': today.toIso8601String(),
            })
            .eq('user_id', userId);
      }
    }
  }

  Future<Map<String, dynamic>> getUserStreak(String userId) async {
    final response =
        await _client
            .from('user_streaks')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    return response ??
        {'current_streak': 0, 'longest_streak': 0, 'last_completed_date': null};
  }
}
