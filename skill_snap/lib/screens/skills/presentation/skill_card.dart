import 'package:flutter/material.dart';
import '../../../services/superbase_service.dart';
import '../data/skill_model.dart';
import './skill_details_screen.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final bool showActions;
  final bool isClickable;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SkillCard({
    super.key,
    required this.skill,
    this.showActions = false,
    this.isClickable = true,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00796B);
    final isRequest = skill.type == 'request';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            isClickable
                ? onTap ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SkillDetailScreen(skill: skill),
                        ),
                      );
                    }
                : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isRequest
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.teal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRequest ? Colors.orange : Colors.teal,
                      ),
                    ),
                    child: Text(
                      isRequest ? 'REQUEST' : 'OFFER',
                      style: TextStyle(
                        color: isRequest ? Colors.orange : Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (showActions)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Skill Title
              Text(
                skill.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // For requests, show what they're offering in exchange
              if (isRequest &&
                  skill.exchangeSkills != null &&
                  skill.exchangeSkills!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offering in exchange:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          skill.exchangeSkills!
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  backgroundColor: Colors.green.withOpacity(
                                    0.2,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),

              // Skill Description (truncated)
              if (skill.description != null)
                Text(
                  skill.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              const SizedBox(height: 16),

              // Footer with user info and date
              Row(
                children: [
                  // User avatar and name
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor, width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                skill.userAvatar != null
                                    ? NetworkImage(skill.userAvatar!)
                                    : null,
                            child:
                                skill.userAvatar == null
                                    ? Icon(
                                      Icons.person,
                                      size: 16,
                                      color: primaryColor,
                                    )
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skill.userName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                skill.userEmail,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date
                  Text(
                    '${skill.createdAt.day}/${skill.createdAt.month}/${skill.createdAt.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
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
}
