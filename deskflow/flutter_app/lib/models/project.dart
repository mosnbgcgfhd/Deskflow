class Project {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
