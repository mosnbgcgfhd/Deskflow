import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';

/// Real aggregate queries against `tasks` — no hardcoded percentages.
class ReportsScreen extends StatefulWidget {
  final String organizationId;
  final List<Profile> orgMembers;
  const ReportsScreen({super.key, required this.organizationId, required this.orgMembers});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _client = Supabase.instance.client;
  bool _loading = true;

  int _completed = 0;
  int _inProgress = 0;
  int _overdue = 0;
  int _total = 0;
  Map<String, int> _completedByAssignee = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allTasks = await _client
        .from('tasks')
        .select('status, assigned_to, due_date')
        .eq('organization_id', widget.organizationId);
    final rows = (allTasks as List).cast<Map<String, dynamic>>();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    int completed = 0, inProgress = 0, overdue = 0;
    final byAssignee = <String, int>{};

    for (final r in rows) {
      final status = r['status'] as String;
      if (status == 'done') {
        completed++;
        final assignee = r['assigned_to'] as String?;
        if (assignee != null) byAssignee[assignee] = (byAssignee[assignee] ?? 0) + 1;
      } else if (status == 'in_progress') {
        inProgress++;
      }
      final due = r['due_date'] as String?;
      if (status != 'done' && due != null && due.compareTo(today) < 0) {
        overdue++;
      }
    }

    setState(() {
      _completed = completed;
      _inProgress = inProgress;
      _overdue = overdue;
      _total = rows.length;
      _completedByAssignee = byAssignee;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final progress = _total == 0 ? 0.0 : _completed / _total;
    final nameOf = {for (final m in widget.orgMembers) m.id: m.fullName};

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
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
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _statRow('Completed', _completed, AppTheme.success),
                    _statRow('In Progress', _inProgress, AppTheme.warning),
                    _statRow('Overdue', _overdue, AppTheme.danger),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Team Performance', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_completedByAssignee.isEmpty)
                      const Text('No completed tasks yet.', style: TextStyle(color: AppTheme.textSecondary))
                    else
                      ..._completedByAssignee.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 120, child: Text(nameOf[e.key] ?? 'Unknown')),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: _completed == 0 ? 0 : e.value / _completed,
                                    minHeight: 10,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.value}'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
