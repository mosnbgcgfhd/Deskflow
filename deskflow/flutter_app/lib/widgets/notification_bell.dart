import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

/// Real notification bell: loads existing unread notifications on
/// mount, then a Realtime subscription pushes new ones in live —
/// this was defined in NotificationService before but never actually
/// shown anywhere in the UI.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _service = NotificationService();
  List<NotificationItem> _items = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.fetchMine();
    setState(() => _items = items);
    _channel = _service.subscribeToMine((item) => setState(() => _items = [item, ..._items]));
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  int get _unreadCount => _items.where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Notifications',
      itemBuilder: (context) {
        if (_items.isEmpty) {
          return [const PopupMenuItem(enabled: false, child: Text('No notifications yet'))];
        }
        return _items.take(10).map((n) {
          return PopupMenuItem(
            onTap: () => _service.markRead(n.id),
            child: SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                  if (n.body != null)
                    Text(n.body!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined),
            if (_unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
