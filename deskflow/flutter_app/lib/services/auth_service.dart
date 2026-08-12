import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

/// Wraps Supabase Auth + the current user's profile (which carries
/// organization_id and role — the two things RLS keys off of).
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }
  Future<void> setPresence(String status) async {
  final id = _client.auth.currentUser?.id;
  if (id == null) return;
  await _client.from('profiles').update({'presence': status}).eq('id', id);
}

  Future<void> signOut() => _client.auth.signOut();

  /// Creates a brand-new organization AND makes the calling user its Admin.
  /// This is the "Create Organization" first-run flow.
  Future<void> createOrganizationAndAdmin({
    required String orgName,
    required String fullName,
  }) async {
    final userId = currentUser!.id;

    final org = await _client
        .from('organizations')
        .insert({'name': orgName, 'created_by': userId})
        .select()
        .single();

    await _client.from('profiles').insert({
      'id': userId,
      'organization_id': org['id'],
      'full_name': fullName,
      'role': 'admin',
    });
  }

  Future<Profile> fetchMyProfile() async {
    final userId = currentUser!.id;
    final row = await _client.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(row);
  }
}
