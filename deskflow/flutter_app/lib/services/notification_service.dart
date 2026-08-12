import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';

/// In-app notifications only for V1 (decision: native OS/system-tray
/// push notifications, which require the app to keep running in the
/// background after the window is closed, are deferred to V2).
class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<NotificationItem>> fetchMine() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('notifications')
        .select()
        .eq('recipient_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => NotificationItem.fromMap(r)).toList();
  }

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<void> send({
    required String organizationId,
    required String recipientId,
    required String title,
    String? body,
  }) async {
    await _client.from('notifications').insert({
      'organization_id': organizationId,
      'recipient_id': recipientId,
      'title': title,
      'body': body,
    });
  }

  /// Realtime bell icon: badge updates the instant a row is inserted
  /// for the current user, no polling needed.
  RealtimeChannel subscribeToMine(void Function(NotificationItem item) onInsert) {
    final userId = _client.auth.currentUser!.id;
    final channel = _client
        .channel('notifications:user:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) => onInsert(NotificationItem.fromMap(payload.newRecord)),
        )
        .subscribe();
    return channel;
  }
}
