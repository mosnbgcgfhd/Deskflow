import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Project Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.82,
                      minHeight: 14,
                      backgroundColor: Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('82%', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Task and team-performance breakdowns query aggregate counts from '
            'the tasks table (grouped by status / assignee) — wire up once '
            'real project data exists.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
