class ActivityItem {
  final String id;
  final String actorId;
  final String action;
  final String targetType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.actorId,
    required this.action,
    required this.targetType,
    required this.metadata,
    required this.createdAt,
  });

  factory ActivityItem.fromMap(Map<String, dynamic> map) {
    return ActivityItem(
      id: map['id'] as String,
      actorId: map['actor_id'] as String,
      action: map['action'] as String,
      targetType: map['target_type'] as String,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Human readable line for the Activity feed, e.g.
  /// "Ahmed created a task"
  String describe(String actorName) {
    switch (action) {
      case 'created_task':
        return '$actorName created a task';
      case 'completed_task':
        return '$actorName completed "${metadata['task_title'] ?? ''}"';
      case 'moved_task':
        return '$actorName moved "${metadata['task_title'] ?? ''}" -> ${metadata['to_status'] ?? ''}';
      case 'uploaded_document':
        return '$actorName uploaded ${metadata['file_name'] ?? 'a document'}';
      case 'added_member':
        return '$actorName added ${metadata['member_name'] ?? 'a member'} to the project';
      default:
        return '$actorName performed $action';
    }
  }
}
