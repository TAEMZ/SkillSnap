import 'package:flutter/material.dart';

class StreakDisplayWidget extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakDisplayWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  State<StreakDisplayWidget> createState() => _StreakDisplayWidgetState();
}

class _StreakDisplayWidgetState extends State<StreakDisplayWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildCurrentStreak(), _buildPersonalBest()],
          ),
          if (widget.currentStreak > 0) ...[
            const SizedBox(height: 16),
            _buildProgressToNextMilestone(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStreak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Streak',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.currentStreak > 0 ? _pulseAnimation.value : 1.0,
                  child: Text(
                    '🔥 ${widget.currentStreak}',
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
              widget.currentStreak == 1 ? 'day' : 'days',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalBest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Personal Best',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          '🏆 ${widget.longestStreak}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressToNextMilestone() {
    final daysToNextMilestone = 7 - (widget.currentStreak % 7);
    final progress = (widget.currentStreak % 7) / 7;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        Text(
          daysToNextMilestone == 7
              ? 'Milestone reached! 🎉'
              : '$daysToNextMilestone days until next milestone',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
