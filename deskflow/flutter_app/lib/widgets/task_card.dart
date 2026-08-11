import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  Color get _priorityColor {
    switch (task.priority) {
      case 'high':
        return AppTheme.danger;
      case 'low':
        return AppTheme.success;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: _priorityColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(task.priority, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  if (task.dueDate != null) ...[
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('${task.dueDate!.day}/${task.dueDate!.month}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
