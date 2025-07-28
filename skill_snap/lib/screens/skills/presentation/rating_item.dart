import 'package:flutter/material.dart';
import '../data/rating_model.dart';

class RatingItem extends StatelessWidget {
  final Rating rating;

  const RatingItem({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      rating.fromUserAvatar != null
                          ? NetworkImage(rating.fromUserAvatar!)
                          : null,
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Text(rating.fromUserName),
                const Spacer(),
                Text('${rating.rating}/5'),
              ],
            ),
            if (rating.feedback != null) ...[
              const SizedBox(height: 8),
              Text(rating.feedback!),
            ],
            const SizedBox(height: 4),
            Text(
              '${rating.createdAt.day}/${rating.createdAt.month}/${rating.createdAt.year}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
