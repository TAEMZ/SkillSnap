import 'package:flutter/material.dart';
import './data/sklil_repository.dart';
import 'data/rating_model.dart';

class SkillController with ChangeNotifier {
  final SkillRepository _repository = SkillRepository();

  Future<void> addRating({
    required String skillId,
    required String toUserId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _repository.addRating(
        skillId: skillId,
        toUser: toUserId,
        rating: rating,
        feedback: feedback,
      );
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  Future<List<Rating>> getSkillRatings(String skillId) async {
    try {
      return await _repository.getSkillRatings(skillId);
    } catch (e) {
      throw Exception('Failed to load ratings: $e');
    }
  }
}
