import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sparks/sparks_model.dart';
import '../sparks/spark_repository.dart';
import '../../../services/spark_service.dart';
import './interactive_challenge.dart';
import './challenge_types.dart';

class SparksScreen extends StatefulWidget {
  const SparksScreen({super.key});

  @override
  State<SparksScreen> createState() => _SparksScreenState();
}

class _SparksScreenState extends State<SparksScreen>
    with TickerProviderStateMixin {
  late Future<List<Spark>> _sparksFuture;
  late Future<Map<String, dynamic>> _streakFuture;
  late SparkRepository _repository;
  final _notesController = TextEditingController();
  String? _userId;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _userId = client.auth.currentUser?.id;
    _repository = SparkRepository(
      client: client,
      geminiService: GeminiService(
        apiKey: 'AIzaSyANv2R9ShPfIMS8ztxAlENi-tE2hd1C8TA',
      ),
    );

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _refreshData();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (_userId == null) return;

    setState(() {
      _sparksFuture = _repository.getDailySparks(userId: _userId!);
      _streakFuture = _repository.getUserStreak(_userId!);
    });
  }

  Future<void> _completeSpark(String sparkId) async {
    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      await _repository.completeSpark(
        sparkId: sparkId,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      _notesController.clear();

      // Get streak info before refresh
      final currentStreak = await _streakFuture;
      _refreshData();
      final newStreak = await _repository.getUserStreak(_userId!);

      if ((newStreak['current_streak'] as int) >
          (currentStreak['current_streak'] as int)) {
        _showStreakCelebration(newStreak['current_streak'] as int);
      } else {
        _showCompletionFeedback();
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _showCompletionFeedback([bool? isCorrect, String? feedback]) {
    HapticFeedback.lightImpact();

    final isInteractive = isCorrect != null;
    final success = isInteractive ? isCorrect : true;
    final message =
        isInteractive
            ? (success
                ? 'Correct! ${feedback ?? ''}'
                : 'Try again: ${feedback ?? ''}')
            : 'Challenge completed! 🎉';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.warning,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: success ? Colors.green[600] : Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showStreakCelebration(int streak) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[800]!,
                    Colors.orange[600]!,
                    Colors.yellow[600]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/fireworks.json',
                    width: 150,
                    height: 150,
                    repeat: false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '🔥 $streak Day Streak!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStreakMessage(streak),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange[800],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Keep Going! 🚀',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _getStreakMessage(int streak) {
    if (streak <= 3) return 'Great start! Keep building momentum!';
    if (streak <= 7) return 'One week strong! You\'re on fire!';
    if (streak <= 14) return 'Two weeks! You\'re unstoppable!';
    if (streak <= 30) return 'A month of growth! Incredible dedication!';
    return 'You\'re a legend! ${streak} days of consistent growth!';
  }

  Future<void> _showInteractiveChallenge(Spark spark) async {
    if (spark.challengeData == null) {
      // Fallback to simple completion dialog for sparks without challenge data
      _showSimpleCompletionDialog(spark);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => InteractiveChallengeWidget(
            spark: spark,
            onComplete: (isCorrect, feedback) {
              Navigator.pop(context);
              _handleChallengeCompletion(spark.id, isCorrect, feedback);
            },
            onCancel: () => Navigator.pop(context),
          ),
    );
  }

  Future<void> _showSimpleCompletionDialog(Spark spark) async {
    return showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[400]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[400]!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getSparkIcon(spark.skillCategory),
                          color: Colors.orange[400],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Challenge',
                              style: TextStyle(
                                color: Colors.orange[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              spark.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      spark.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reflection (Optional)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'How did it go? What did you learn?',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.orange[400]!,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[400],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _completeSpark(spark.id);
                          },
                          child: const Text(
                            'Complete Challenge 🎉',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _handleChallengeCompletion(
    String sparkId,
    bool isCorrect,
    String feedback,
  ) async {
    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      await _repository.completeSpark(
        sparkId: sparkId,
        notes:
            isCorrect
                ? 'Completed successfully: $feedback'
                : 'Attempted: $feedback',
      );

      // Get streak info before refresh
      final currentStreak = await _streakFuture;
      _refreshData();
      final newStreak = await _repository.getUserStreak(_userId!);

      if ((newStreak['current_streak'] as int) >
          (currentStreak['current_streak'] as int)) {
        _showStreakCelebration(newStreak['current_streak'] as int);
      } else {
        _showCompletionFeedback(isCorrect, feedback);
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  IconData _getSparkIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'design':
        return Icons.palette;
      case 'coding':
      case 'programming':
        return Icons.code;
      case 'writing':
        return Icons.edit;
      case 'fitness':
        return Icons.fitness_center;
      case 'music':
        return Icons.music_note;
      case 'language':
        return Icons.translate;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [_buildAppBar(), _buildStreakSection(), _buildSparksSection()],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Daily Sparks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.orange[900]!.withOpacity(0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
        ),
      ],
    );
  }

  Widget _buildStreakSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[800]!, Colors.orange[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _streakFuture,
            builder: (context, snapshot) {
              final streak = snapshot.data?['current_streak'] ?? 0;
              final longestStreak = snapshot.data?['longest_streak'] ?? 0;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Streak',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale:
                                        streak > 0
                                            ? _pulseAnimation.value
                                            : 1.0,
                                    child: Text(
                                      '🔥 $streak',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                streak == 1 ? 'day' : 'days',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Personal Best',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '🏆 $longestStreak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (streak > 0) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (streak % 7) / 7,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${7 - (streak % 7)} days until next milestone',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSparksSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: FutureBuilder<List<Spark>>(
        future: _sparksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: _buildErrorState(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return SliverToBoxAdapter(child: _buildEmptyState());
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final spark = snapshot.data![index];
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.3 + (index * 0.1)),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: Interval(index * 0.1, 1.0, curve: Curves.elasticOut),
                  ),
                ),
                child: _buildSparkCard(spark, index),
              );
            }, childCount: snapshot.data!.length),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[400]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            onPressed: _refreshData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration, color: Colors.orange[400], size: 48),
          const SizedBox(height: 16),
          Text(
            'All done for today! 🎉',
            style: TextStyle(
              color: Colors.orange[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ve completed all your daily sparks.\nCome back tomorrow for new challenges!',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSparkCard(Spark spark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInteractiveChallenge(spark),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[850]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getDifficultyColor(spark.difficulty).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getChallengeTypeColor(
                          spark.challengeData?.type,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getChallengeTypeIcon(spark.challengeData?.type),
                        color: _getChallengeTypeColor(
                          spark.challengeData?.type,
                        ),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildBadge(
                                '${spark.durationMinutes} min',
                                Colors.blue[400]!,
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                spark.difficulty.toUpperCase(),
                                _getDifficultyColor(spark.difficulty),
                              ),
                              if (spark.challengeData != null) ...[
                                const SizedBox(width: 8),
                                _buildBadge(
                                  _getChallengeTypeLabel(
                                    spark.challengeData!.type,
                                  ),
                                  _getChallengeTypeColor(
                                    spark.challengeData!.type,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  spark.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  spark.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                if (spark.skillCategory != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[400]!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[400]!),
                    ),
                    child: Text(
                      spark.skillCategory!,
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.0, // Start at 0, will be 1.0 when completed
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getChallengeTypeColor(spark.challengeData?.type),
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      spark.challengeData != null
                          ? Icons.play_arrow
                          : Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green[400]!;
      case 'intermediate':
        return Colors.orange[400]!;
      case 'advanced':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Color _getChallengeTypeColor(ChallengeType? type) {
    switch (type) {
      case ChallengeType.multipleChoice:
        return Colors.blue[400]!;
      case ChallengeType.textInput:
      case ChallengeType.writingPrompt:
        return Colors.purple[400]!;
      case ChallengeType.codeChallenge:
        return Colors.green[400]!;
      case ChallengeType.mathProblem:
        return Colors.cyan[400]!;
      case ChallengeType.languageTranslation:
        return Colors.pink[400]!;
      case ChallengeType.designChallenge:
        return Colors.indigo[400]!;
      default:
        return Colors.orange[400]!;
    }
  }

  IconData _getChallengeTypeIcon(ChallengeType? type) {
    switch (type) {
      case ChallengeType.multipleChoice:
        return Icons.quiz;
      case ChallengeType.textInput:
      case ChallengeType.writingPrompt:
        return Icons.edit;
      case ChallengeType.codeChallenge:
        return Icons.code;
      case ChallengeType.mathProblem:
        return Icons.calculate;
      case ChallengeType.languageTranslation:
        return Icons.translate;
      case ChallengeType.designChallenge:
        return Icons.palette;
      case ChallengeType.drawingChallenge:
        return Icons.brush;
      case ChallengeType.photoChallenge:
        return Icons.camera_alt;
      case ChallengeType.audioChallenge:
        return Icons.mic;
      default:
        return Icons.psychology;
    }
  }

  String _getChallengeTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.multipleChoice:
        return 'QUIZ';
      case ChallengeType.textInput:
        return 'TEXT';
      case ChallengeType.writingPrompt:
        return 'WRITE';
      case ChallengeType.codeChallenge:
        return 'CODE';
      case ChallengeType.mathProblem:
        return 'MATH';
      case ChallengeType.languageTranslation:
        return 'TRANSLATE';
      case ChallengeType.designChallenge:
        return 'DESIGN';
      case ChallengeType.drawingChallenge:
        return 'DRAW';
      case ChallengeType.photoChallenge:
        return 'PHOTO';
      case ChallengeType.audioChallenge:
        return 'AUDIO';
    }
  }
}
