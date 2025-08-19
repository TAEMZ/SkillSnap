import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _apiKey = 'AIzaSyANv2R9ShPfIMS8ztxAlENi-tE2hd1C8TA';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> getLearningRecommendations({
    required String userId,
    required List<String> userSkills,
  }) async {
    try {
      final prompt = '''
You are a career coach AI helping a user upskill.
${userSkills.isNotEmpty ? 'The user has these skills: ${userSkills.join(', ')}.' : 'The user has not listed any skills yet.'}

Provide 3 personalized course recommendations in valid JSON format following this exact structure:

{
  "recommendations": [
    {
      "title": "Course title",
      "skill": "Primary skill",
      "level": "Beginner/Intermediate/Advanced",
      "resources": [
        {
          "name": "Resource name", 
          "type": "course",
          "url": "https://www.udemy.com/course/..."  // Add URL field
        }
      ],
      "match_score": 85
    }
  ]
}

Important rules:
1. Return ONLY the JSON object
2. Do NOT include markdown formatting (no ```json)
3. Ensure all brackets and quotes are properly closed
4. Maintain consistent formatting
5. match_score should be between 0-100
6. Resource types must be one of: course, video, article, documentation

${userSkills.isEmpty ? 'Focus on general digital skills.' : 'Recommend specific next-level skills.'}
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
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
            "temperature": 0.5,
            "response_mime_type": "application/json",
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      final content =
          jsonResponse["candidates"][0]["content"]["parts"][0]["text"].trim();

      // Clean response by removing markdown code blocks if they exist
      final cleanedResponse =
          content.replaceAll('```json', '').replaceAll('```', '').trim();

      // Validate it's proper JSON
      final json = jsonDecode(cleanedResponse);
      if (json['recommendations'] == null) {
        throw FormatException('Invalid response format from Gemini');
      }

      return cleanedResponse;
    } catch (e) {
      debugPrint('Gemini API error: $e');
      throw Exception('Failed to get recommendations: ${e.toString()}');
    }
  }

  Future<String> searchCourses({required String query}) async {
    try {
      final prompt = '''
I need you to recommend courses based on this search query: "$query".
Provide results in the same JSON format as before.

Response format:
{
  "recommendations": [
    {
      "title": "Course title",
      "skill": "Relevant skill",
      "level": "Beginner/Intermediate/Advanced",
      "resources": [
        {
          "name": "Resource name", 
          "type": "course",
          "url": "https://platform.com/course-url"
        }
      ],
      "match_score": 85
    }
  ]
}

Focus on:
1. Most popular and high-quality courses
2. Include direct URLs when possible
3. Match the query intent
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
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
            "temperature": 0.7, // Slightly higher for broader results
            "response_mime_type": "application/json",
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final content =
          jsonResponse["candidates"][0]["content"]["parts"][0]["text"].trim();
      return content.replaceAll('```json', '').replaceAll('```', '').trim();
    } catch (e) {
      debugPrint('Search error: $e');
      throw Exception('Failed to search courses: ${e.toString()}');
    }
  }
}
