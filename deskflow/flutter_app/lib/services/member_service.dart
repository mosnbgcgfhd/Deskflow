import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'email_service.dart';

class MemberService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Profile>> fetchOrgMembers() async {
    final rows = await _client.from('profiles').select().order('full_name');
    return (rows as List).map((r) => Profile.fromMap(r)).toList();
  }

  Future<Map<String, String>> fetchNameMap() async {
    final members = await fetchOrgMembers();
    return {for (final m in members) m.id: m.fullName};
  }

  /// Creates a pending invite row. The invited person then signs up from
  /// the "Join your organization" screen and gets linked automatically.
   /// Sends an invitation email via EmailJS, then records the invite row.
  /// The invited person signs up from "Join your organization".
  Future<void> inviteEmployee({
    required String email,
    required String fullName,
    required String role,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final me = await _client
        .from('profiles')
        .select('organization_id, full_name')
        .eq('id', userId)
        .single();

    // 1) Send the email FIRST — if it fails, no invite row is created
    await EmailService.sendInviteEmail(
      toEmail: email.trim().toLowerCase(),
      toName: fullName.trim(),
      roleName: role,
      invitedByName: me['full_name'] as String,
    );

    // 2) Then record the pending invite
    await _client.from('invites').insert({
      'organization_id': me['organization_id'] as String,
      'email': email.trim().toLowerCase(),
      'full_name': fullName.trim(),
      'role': role,
      'invited_by': userId,
    });
  }
}