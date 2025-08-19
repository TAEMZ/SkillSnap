import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/learning/sparks/challenge_types.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<List<Map<String, dynamic>>> generateSparks({
    required List<String> userSkills,
    int count = 3,
  }) async {
    try {
      final prompt = '''
-You are a micro-challenge generator for skill development. Create $count personalized daily challenges (5-15 minutes each) based on the user's skills.
+You are an interactive micro-challenge generator for skill development. Create $count personalized daily challenges (5-15 minutes each) based on the user's skills.

 User skills: ${userSkills.isEmpty ? 'None specified' : userSkills.join(', ')}

+IMPORTANT: Each challenge must be INTERACTIVE and completable within the app. Include challenge_data with specific interactive elements.

 Response format (pure JSON, no markdown):
 {
   "sparks": [
     {
       "title": "Challenge title",
       "description": "Detailed instructions",
       "skill_category": "Relevant skill",
       "difficulty": "beginner/intermediate/advanced",
-      "duration_minutes": 5-15
+      "duration_minutes": 5-15,
+      "challenge_data": {
+        "type": "multipleChoice|textInput|codeChallenge|drawingChallenge|photoChallenge|mathProblem|languageTranslation|designChallenge|writingPrompt",
+        "data": {
+          "question": "The main question/prompt",
+          "context": "Additional context if needed",
+          "examples": ["example1", "example2"] // if applicable
+        },
+        "options": ["option1", "option2", "option3", "option4"], // for multiple choice
+        "correct_answer": "correct answer", // for validation
+        "validation_prompt": "Prompt for AI to validate user's answer"
+      }
     }
   ]
 }

+Challenge Types to Use:
+1. multipleChoice: Quiz questions with 4 options
+2. textInput: Open-ended questions requiring text answers
+3. codeChallenge: Simple coding problems
+4. mathProblem: Math equations or word problems
+5. languageTranslation: Translate words/phrases
+6. designChallenge: Describe a design solution
+7. writingPrompt: Creative writing exercises
+8. drawingChallenge: Describe what to draw (user uploads photo)
+9. photoChallenge: Take a photo of something specific
+
 Guidelines:
 1. Make challenges actionable and completable in one sitting
 2. Include at least one fundamental skill if user is beginner
 3. Vary difficulty levels
 4. Focus on practical application
 5. Include creative challenges when possible
 6. Duration should be between 5-15 minutes
+7. ALWAYS include interactive challenge_data
+8. Make validation_prompt specific for AI to check answers
 ''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.7,
            "response_mime_type": "application/json",
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate sparks: ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final content =
          jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      final cleanContent =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanContent);

      return List<Map<String, dynamic>>.from(data['sparks']);
    } catch (e) {
      throw Exception('Failed to generate sparks: ${e.toString()}');
    }
  }

  Future<bool> validateAnswer({
    required String question,
    required String userAnswer,
    required String validationPrompt,
    String? correctAnswer,
  }) async {
    try {
      final prompt = '''
+$validationPrompt
+
+Question: $question
+User's Answer: $userAnswer
+${correctAnswer != null ? 'Expected Answer: $correctAnswer' : ''}
+
+Evaluate if the user's answer is correct, reasonable, or demonstrates understanding.
+
+Response format (pure JSON):
+{
+  "is_correct": true/false,
+  "feedback": "Brief encouraging feedback",
+  "score": 0-100
+}
+''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.3,
            "response_mime_type": "application/json",
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to validate answer: ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final content =
          jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      final cleanContent =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanContent);

      return data['is_correct'] ?? false;
    } catch (e) {
      throw Exception('Failed to validate answer: ${e.toString()}');
    }
  }
}
