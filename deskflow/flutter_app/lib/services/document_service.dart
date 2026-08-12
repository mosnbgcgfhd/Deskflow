import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document.dart';
import 'activity_service.dart';

class DocumentService {
  final SupabaseClient _client = Supabase.instance.client;
  final ActivityService _activityService = ActivityService();

  static const bucket = 'documents';

  Future<List<AppDocument>> fetchForProject(String projectId) async {
    final rows = await _client
        .from('documents')
        .select()
        .eq('project_id', projectId)
        .order('uploaded_at', ascending: false);
    return (rows as List).map((r) => AppDocument.fromMap(r)).toList();
  }

  /// Uploads real file bytes to the org-scoped Storage path
  /// `{organization_id}/{project_id}/{fileName}`, then records the row
  /// in `documents` and writes an Activity Log entry — matching the
  /// spec's "every file has an uploader, date, project" requirement.
  Future<AppDocument> upload({
    required String organizationId,
    required String projectId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final storagePath = '$organizationId/$projectId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from(bucket).uploadBinary(storagePath, bytes);

    final row = await _client
        .from('documents')
        .insert({
          'organization_id': organizationId,
          'project_id': projectId,
          'file_name': fileName,
          'storage_path': storagePath,
          'uploaded_by': userId,
        })
        .select()
        .single();

    await _activityService.log(
      organizationId: organizationId,
      action: 'uploaded_document',
      targetType: 'document',
      targetId: row['id'] as String,
      metadata: {'file_name': fileName},
    );

    return AppDocument.fromMap(row);
  }

  /// Signed URL so the file can actually be opened/downloaded — the
  /// bucket is private, so a raw public URL won't work.
  Future<String> getDownloadUrl(String storagePath) async {
    return _client.storage.from(bucket).createSignedUrl(storagePath, 60 * 10);
  }

  Future<void> delete(AppDocument doc) async {
    await _client.storage.from(bucket).remove([doc.storagePath]);
    await _client.from('documents').delete().eq('id', doc.id);
  }
}
