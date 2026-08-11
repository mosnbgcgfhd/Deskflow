import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/task.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> fetchTasksForProject(String projectId) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('updated_at', ascending: false);
    return (rows as List).map((r) => Task.fromMap(r)).toList();
  }

  Future<Task> createTask({
    required String organizationId,
    required String projectId,
    required String title,
    String? description,
    String? assignedTo,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    final row = await _client
        .from('tasks')
        .insert({
          'organization_id': organizationId,
          'project_id': projectId,
          'title': title,
          'description': description,
          'assigned_to': assignedTo,
          'priority': priority,
          'due_date': dueDate?.toIso8601String(),
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return Task.fromMap(row);
  }

  /// Drives the Kanban drag-and-drop: updates status, which the
  /// `trg_tasks_updated_at` trigger stamps, which every other
  /// connected client picks up via the Realtime subscription below.
  Future<void> moveTask(String taskId, TaskStatus newStatus) async {
    await _client.from('tasks').update({'status': newStatus.dbValue}).eq('id', taskId);
  }

  /// One realtime channel per project, used to keep every connected
  /// user's Kanban board in sync without a manual refresh.
  RealtimeChannel subscribeToProjectTasks(
    String projectId,
    void Function(Task task, String eventType) onChange,
  ) {
    final channel = _client
        .channel('tasks:project:$projectId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'project_id',
            value: projectId,
          ),
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            onChange(Task.fromMap(record), payload.eventType.name);
          },
        )
        .subscribe();
    return channel;
  }
}
