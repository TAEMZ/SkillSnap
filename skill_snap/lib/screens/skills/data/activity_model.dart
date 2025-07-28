import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

// activity_model.dart
class Activity {
  final String id;
  final String type; // 'message', 'match', 'rating'
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;

  Activity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.onTap,
  });
}
