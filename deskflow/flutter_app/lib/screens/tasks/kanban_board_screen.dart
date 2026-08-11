import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../widgets/kanban_column.dart';
import 'create_task_dialog.dart';

/// The Kanban board: TODO -> IN PROGRESS -> IN REVIEW -> DONE.
/// Backed by Supabase Realtime so every teammate viewing the same
/// project sees drags/status-changes appear live, without refreshing.
class KanbanBoardScreen extends StatefulWidget {
  final Project project;
  const KanbanBoardScreen({super.key, required this.project});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final _taskService = TaskService();
  List<Task> _tasks = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _taskService.fetchTasksForProject(widget.project.id);
    setState(() => _tasks = tasks);

    // Live sync: any teammate's drag-and-drop or edit on this board
    // arrives here instantly via a Postgres changefeed subscription.
    _channel = _taskService.subscribeToProjectTasks(widget.project.id, (task, eventType) {
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
        if (eventType != 'delete') _tasks.add(task);
      });
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  List<Task> _byStatus(TaskStatus status) => _tasks.where((t) => t.status == status).toList();

  Future<void> _onDrop(Task task, TaskStatus newStatus) async {
    if (task.status == newStatus) return;
    // Optimistic local update; the Realtime event that follows is a no-op
    // confirmation (or corrects us if another user changed it first).
    setState(() {
      _tasks = _tasks.map((t) => t.id == task.id ? t.copyWith(status: newStatus) : t).toList();
    });
    await _taskService.moveTask(task.id, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => CreateTaskDialog(
              organizationId: widget.project.organizationId,
              projectId: widget.project.id,
            ),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (final status in TaskStatus.values) ...[
              KanbanColumn(
                status: status,
                tasks: _byStatus(status),
                onTaskDropped: _onDrop,
              ),
              if (status != TaskStatus.values.last) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}
