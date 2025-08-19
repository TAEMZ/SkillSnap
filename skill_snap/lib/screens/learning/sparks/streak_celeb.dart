import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class StreakCelebrationWidget extends StatefulWidget {
  final int streak;
  final VoidCallback onDismiss;

  const StreakCelebrationWidget({
    super.key,
    required this.streak,
    required this.onDismiss,
  });

  @override
  State<StreakCelebrationWidget> createState() =>
      _StreakCelebrationWidgetState();
}

class _StreakCelebrationWidgetState extends State<StreakCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
    _rotationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _getStreakMessage(int streak) {
    if (streak <= 3) return 'Great start! Keep building momentum!';
    if (streak <= 7) return 'One week strong! You\'re on fire!';
    if (streak <= 14) return 'Two weeks! You\'re unstoppable!';
    if (streak <= 30) return 'A month of growth! Incredible dedication!';
    return 'You\'re a legend! ${streak} days of consistent growth!';
  }

  List<String> _getStreakEmojis(int streak) {
    if (streak <= 3) return ['🌱', '💪', '🚀'];
    if (streak <= 7) return ['🔥', '⚡', '🎯'];
    if (streak <= 14) return ['🏆', '💎', '🌟'];
    if (streak <= 30) return ['👑', '🦄', '✨'];
    return ['🏅', '🎊', '🎉', '🔥', '💫'];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: Container(
            padding: const EdgeInsets.all(32),
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
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFireworks(),
                const SizedBox(height: 20),
                _buildStreakDisplay(),
                const SizedBox(height: 16),
                _buildMessage(),
                const SizedBox(height: 20),
                _buildEmojis(),
                const SizedBox(height: 28),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFireworks() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        children: [
          Lottie.asset(
            'assets/animations/fireworks.json',
            width: 160,
            height: 160,
            repeat: false,
          ),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDisplay() {
    return Column(
      children: [
        Text(
          '🔥 ${widget.streak}',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          widget.streak == 1 ? 'Day Streak!' : 'Day Streak!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    return Text(
      _getStreakMessage(widget.streak),
      style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmojis() {
    final emojis = _getStreakEmojis(widget.streak);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          emojis
              .map(
                (emoji) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              )
              .toList(),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      onPressed: widget.onDismiss,
      child: const Text(
        'Keep Going! 🚀',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
