import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './challenge_types.dart';
import '../sparks/sparks_model.dart';
import '../sparks/challenges/mulltiple_choice.dart';
import '../sparks/challenges/text_input.dart';
import '../sparks/challenges/code_challenge.dart';
import '../../../services/spark_service.dart';

class InteractiveChallengeWidget extends StatefulWidget {
  final Spark spark;
  final Function(bool isCorrect, String feedback) onComplete;
  final VoidCallback onCancel;

  const InteractiveChallengeWidget({
    super.key,
    required this.spark,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<InteractiveChallengeWidget> createState() =>
      _InteractiveChallengeWidgetState();
}

class _InteractiveChallengeWidgetState extends State<InteractiveChallengeWidget>
    with TickerProviderStateMixin {
  String userAnswer = '';
  bool isLoading = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  final GeminiService _geminiService = GeminiService(
    apiKey: 'AIzaSyANv2R9ShPfIMS8ztxAlENi-tE2hd1C8TA',
  );

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (userAnswer.trim().isEmpty) {
      _showSnackBar('Please provide an answer first!', Colors.orange);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();

      final challengeData = widget.spark.challengeData!;
      final question =
          challengeData.data['question'] ?? widget.spark.description;

      bool isCorrect;

      // For multiple choice, check directly
      if (challengeData.type == ChallengeType.multipleChoice) {
        isCorrect = userAnswer == challengeData.correctAnswer;
      } else {
        // For other types, use AI validation
        isCorrect = await _geminiService.validateAnswer(
          question: question,
          userAnswer: userAnswer,
          validationPrompt:
              challengeData.validationPrompt ??
              'Evaluate if this answer demonstrates understanding of the topic.',
          correctAnswer: challengeData.correctAnswer,
        );
      }

      final feedback =
          isCorrect ? _getPositiveFeedback() : _getEncouragingFeedback();

      widget.onComplete(isCorrect, feedback);
    } catch (e) {
      _showSnackBar('Error validating answer: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getPositiveFeedback() {
    final feedbacks = [
      'Excellent work! 🎉',
      'Perfect! You nailed it! ⭐',
      'Outstanding answer! 🚀',
      'Brilliant! Keep it up! 💫',
      'Fantastic job! 🔥',
    ];
    return feedbacks[DateTime.now().millisecond % feedbacks.length];
  }

  String _getEncouragingFeedback() {
    final feedbacks = [
      'Good effort! Keep practicing! 💪',
      'Nice try! You\'re learning! 📚',
      'Great attempt! Try again tomorrow! 🌟',
      'You\'re on the right track! 🎯',
      'Keep going! Progress takes time! ⏰',
    ];
    return feedbacks[DateTime.now().millisecond % feedbacks.length];
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildChallengeWidget() {
    final challengeData = widget.spark.challengeData!;

    switch (challengeData.type) {
      case ChallengeType.multipleChoice:
        return MultipleChoiceWidget(
          question: challengeData.data['question'] ?? widget.spark.description,
          options: challengeData.options ?? [],
          correctAnswer: challengeData.correctAnswer,
          onAnswerSelected: (answer) {
            setState(() {
              userAnswer = answer;
            });
          },
        );

      case ChallengeType.textInput:
      case ChallengeType.writingPrompt:
        return TextInputWidget(
          question: challengeData.data['question'] ?? widget.spark.description,
          context: challengeData.data['context'],
          placeholder:
              challengeData.type == ChallengeType.writingPrompt
                  ? 'Write your creative response...'
                  : 'Type your answer...',
          onAnswerChanged: (answer) {
            setState(() {
              userAnswer = answer;
            });
          },
        );

      case ChallengeType.codeChallenge:
        return CodeChallengeWidget(
          question: challengeData.data['question'] ?? widget.spark.description,
          context: challengeData.data['context'],
          examples: challengeData.data['examples']?.cast<String>(),
          onCodeChanged: (code) {
            setState(() {
              userAnswer = code;
            });
          },
        );

      default:
        return TextInputWidget(
          question: challengeData.data['question'] ?? widget.spark.description,
          onAnswerChanged: (answer) {
            setState(() {
              userAnswer = answer;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange[400]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[400]!.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: Colors.orange[400],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.spark.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.spark.durationMinutes} min • ${widget.spark.difficulty}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Challenge Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildChallengeWidget(),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: widget.onCancel,
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
                          backgroundColor:
                              userAnswer.trim().isEmpty
                                  ? Colors.grey[600]
                                  : Colors.orange[400],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                            userAnswer.trim().isEmpty || isLoading
                                ? null
                                : _submitAnswer,
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Submit Answer 🚀',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
