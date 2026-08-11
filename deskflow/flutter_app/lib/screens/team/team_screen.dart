import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _client = Supabase.instance.client;
  List<Profile> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _client.from('profiles').select();
    setState(() {
      _members = (rows as List).map((r) => Profile.fromMap(r)).toList();
      _loading = false;
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
          Row(
            children: [
              const Text('Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {}, // opens an "Invite employee" dialog (admin/manager only, enforced by RLS)
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('Invite employee'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _members.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = _members[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(m.fullName.isNotEmpty ? m.fullName[0] : '?')),
                  title: Text(m.fullName),
                  subtitle: Text(m.title ?? m.role.dbValue),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 10, color: m.presence == 'online' ? AppTheme.success : Colors.grey),
                      const SizedBox(width: 6),
                      Text(m.presence, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
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
