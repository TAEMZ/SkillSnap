enum ChallengeType {
  multipleChoice,
  textInput,
  codeChallenge,
  drawingChallenge,
  photoChallenge,
  audioChallenge,
  mathProblem,
  languageTranslation,
  designChallenge,
  writingPrompt,
}

class ChallengeData {
  final ChallengeType type;
  final Map<String, dynamic> data;
  final String? correctAnswer;
  final List<String>? options;
  final String? validationPrompt;

  ChallengeData({
    required this.type,
    required this.data,
    this.correctAnswer,
    this.options,
    this.validationPrompt,
  });

  factory ChallengeData.fromJson(Map<String, dynamic> json) {
    return ChallengeData(
      type: ChallengeType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ChallengeType.textInput,
      ),
      data: json['data'] ?? {},
      correctAnswer: json['correct_answer'],
      options: json['options']?.cast<String>(),
      validationPrompt: json['validation_prompt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'data': data,
      'correct_answer': correctAnswer,
      'options': options,
      'validation_prompt': validationPrompt,
    };
  }
}
