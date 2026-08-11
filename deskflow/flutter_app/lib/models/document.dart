class AppDocument {
  final String id;
  final String projectId;
  final String fileName;
  final String storagePath;
  final String uploadedBy;
  final DateTime uploadedAt;

  AppDocument({
    required this.id,
    required this.projectId,
    required this.fileName,
    required this.storagePath,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory AppDocument.fromMap(Map<String, dynamic> map) {
    return AppDocument(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      fileName: map['file_name'] as String,
      storagePath: map['storage_path'] as String,
      uploadedBy: map['uploaded_by'] as String,
      uploadedAt: DateTime.parse(map['uploaded_at'] as String),
    );
  }
}
