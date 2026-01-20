import 'package:dhamma_apk/models/lesson.dart';
import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  const LessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/lesson-detail',
          arguments: lesson.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lesson.class_?.name ?? 'N/A',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (lesson.lessonDate != null)
                    Text(
                      DateFormatUtil.formatDate(lesson.lessonDate!),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (lesson.description != null)
                Text(
                  lesson.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lesson.subject?.name ?? 'N/A',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lesson.durationMinutes != null)
                    Text(
                      '${lesson.durationMinutes}m',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
              if (lesson.teacher != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'By ${lesson.teacher!.name}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
