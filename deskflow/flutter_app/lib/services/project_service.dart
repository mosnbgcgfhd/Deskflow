import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';
import 'activity_service.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;
  final ActivityService _activityService = ActivityService();

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
    final project = Project.fromMap(row);

    await _activityService.log(
      organizationId: organizationId,
      action: 'created_project',
      targetType: 'project',
      targetId: project.id,
      metadata: {'project_name': name},
    );

    return project;
  }

  Future<void> addMember(String projectId, String profileId, String organizationId, String memberName) async {
    await _client.from('project_members').insert({
      'project_id': projectId,
      'profile_id': profileId,
    });

    await _activityService.log(
      organizationId: organizationId,
      action: 'added_member',
      targetType: 'project',
      targetId: projectId,
      metadata: {'member_name': memberName},
    );
  }

  Future<List<Map<String, dynamic>>> fetchProjectMembers(String projectId) async {
    final rows = await _client
        .from('project_members')
        .select('profile_id, profiles(id, full_name, role)')
        .eq('project_id', projectId);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
