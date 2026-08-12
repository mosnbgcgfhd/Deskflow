import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/task.dart';
import 'task_card.dart';

/// A single droppable Kanban column. Wrapped in a DragTarget so tasks
/// dragged from other columns update `status` (-> synced to every
/// connected client via the Realtime subscription in TaskService).
class KanbanColumn extends StatelessWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final void Function(Task task, TaskStatus newStatus) onTaskDropped;
  final void Function(Task task)? onTaskTap;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onTaskDropped,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DragTarget<Task>(
        onAcceptWithDetails: (details) => onTaskDropped(details.data, status),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: isHovering ? Colors.indigo.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    '${status.label} (${tasks.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      return Draggable<Task>(
                        data: task,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 220, child: TaskCard(task: task)),
                        ),
                        childWhenDragging: Opacity(opacity: 0.3, child: TaskCard(task: task)),
                        child: TaskCard(task: task, onTap: () => onTaskTap?.call(task)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
