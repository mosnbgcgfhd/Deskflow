import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/task.dart';
import 'activity_service.dart';
import 'notification_service.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;
  final ActivityService _activityService = ActivityService();
  final NotificationService _notificationService = NotificationService();

  Future<List<Task>> fetchTasksForProject(String projectId) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('updated_at', ascending: false);
    return (rows as List).map((r) => Task.fromMap(r)).toList();
  }

  /// Creates the task, logs it to the Activity feed, AND — if it was
  /// assigned to someone — sends them an in-app notification. All three
  /// happen for real here; none of this was wired up before.
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
    final task = Task.fromMap(row);

    await _activityService.log(
      organizationId: organizationId,
      action: 'created_task',
      targetType: 'task',
      targetId: task.id,
      metadata: {'task_title': title},
    );

    if (assignedTo != null) {
      await _notificationService.send(
        organizationId: organizationId,
        recipientId: assignedTo,
        title: 'New task assigned to you',
        body: title,
      );
    }

    return task;
  }

  /// Drives the Kanban drag-and-drop: updates status (which the
  /// `trg_tasks_updated_at` trigger stamps, propagating to every
  /// connected client via Realtime), and logs the move to Activity.
  Future<void> moveTask(Task task, TaskStatus newStatus) async {
    await _client.from('tasks').update({'status': newStatus.dbValue}).eq('id', task.id);

    await _activityService.log(
      organizationId: task.organizationId,
      action: 'moved_task',
      targetType: 'task',
      targetId: task.id,
      metadata: {'task_title': task.title, 'to_status': newStatus.label},
    );

    if (newStatus == TaskStatus.done && task.assignedTo != null) {
      await _activityService.log(
        organizationId: task.organizationId,
        action: 'completed_task',
        targetType: 'task',
        targetId: task.id,
        metadata: {'task_title': task.title},
      );
    }
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
