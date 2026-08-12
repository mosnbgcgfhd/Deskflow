import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_item.dart';

class ActivityService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> log({
    required String organizationId,
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _client.from('activity_log').insert({
      'organization_id': organizationId,
      'actor_id': _client.auth.currentUser!.id,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'metadata': metadata,
    });
  }

  Future<List<ActivityItem>> fetchRecent({int limit = 30}) async {
    final rows = await _client
        .from('activity_log')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => ActivityItem.fromMap(r)).toList();
  }

  /// Live-updating activity feed for the Dashboard screen.
  RealtimeChannel subscribeToOrgActivity(
    String organizationId,
    void Function(ActivityItem item) onInsert,
  ) {
    final channel = _client
        .channel('activity:org:$organizationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'activity_log',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'organization_id',
            value: organizationId,
          ),
          callback: (payload) => onInsert(ActivityItem.fromMap(payload.newRecord)),
        )
        .subscribe();
    return channel;
  }
}
