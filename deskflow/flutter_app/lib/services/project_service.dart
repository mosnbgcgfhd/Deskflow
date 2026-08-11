import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Project>> fetchProjects() async {
    final rows = await _client.from('projects').select().order('created_at', ascending: false);
    return (rows as List).map((r) => Project.fromMap(r)).toList();
  }

  Future<Project> createProject({
    required String organizationId,
    required String name,
    String? description,
  }) async {
    final row = await _client
        .from('projects')
        .insert({
          'organization_id': organizationId,
          'name': name,
          'description': description,
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return Project.fromMap(row);
  }

  Future<void> addMember(String projectId, String profileId) async {
    await _client.from('project_members').insert({
      'project_id': projectId,
      'profile_id': profileId,
    });
  }
}
