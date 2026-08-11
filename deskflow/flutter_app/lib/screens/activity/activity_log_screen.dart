import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/activity_item.dart';
import '../../services/activity_service.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _service = ActivityService();
  List<ActivityItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.fetchRecent(limit: 100).then((items) {
      setState(() {
        _items = items;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = _items[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.circle, size: 8, color: AppTheme.primary),
                  title: Text(a.describe('Someone')),
                  trailing: Text(
                    '${a.createdAt.hour.toString().padLeft(2, '0')}:${a.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
