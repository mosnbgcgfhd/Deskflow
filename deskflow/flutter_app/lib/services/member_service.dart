import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

/// Fetches and caches organization members — used by the Team screen,
/// the task-assignee picker, and to resolve actor_id -> name for the
/// Activity feed (the activity_log table stores only actor_id).
class MemberService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Profile>> fetchOrgMembers() async {
    final rows = await _client.from('profiles').select().order('full_name');
    return (rows as List).map((r) => Profile.fromMap(r)).toList();
  }

  /// Builds a { profile_id: full_name } lookup map in one query, so
  /// screens rendering many activity rows don't do N+1 lookups.
  Future<Map<String, String>> fetchNameMap() async {
    final members = await fetchOrgMembers();
    return {for (final m in members) m.id: m.fullName};
  }

  /// Calls the `invite-user` Supabase Edge Function (see
  /// supabase/functions/invite-user/index.ts). Creating an auth user
  /// requires the service-role key, which must never live in the
  /// client app — so the actual user creation happens server-side,
  /// and the Edge Function itself checks the caller is an org admin
  /// before doing anything.
  Future<void> inviteEmployee({
    required String email,
    required String fullName,
    required String role, // 'manager' | 'employee'
  }) async {
    final res = await _client.functions.invoke(
      'invite-user',
      body: {'email': email, 'full_name': fullName, 'role': role},
    );
    if (res.status != 200) {
      final message = (res.data is Map) ? res.data['error'] : 'Invite failed';
      throw Exception(message ?? 'Invite failed');
    }
  }
}
