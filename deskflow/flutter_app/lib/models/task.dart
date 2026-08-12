import '../core/constants.dart';

class Task {
  final String id;
  final String organizationId;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final String priority; // low | medium | high
  final String? assignedTo;
  final DateTime? dueDate;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.organizationId,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.dueDate,
    required this.updatedAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      projectId: map['project_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: TaskStatusX.fromDb(map['status'] as String),
      priority: map['priority'] as String? ?? 'medium',
      assignedTo: map['assigned_to'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Task copyWith({TaskStatus? status}) {
    return Task(
      id: id,
      organizationId: organizationId,
      projectId: projectId,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority,
      assignedTo: assignedTo,
      dueDate: dueDate,
      updatedAt: DateTime.now(),
    );
  }
}
