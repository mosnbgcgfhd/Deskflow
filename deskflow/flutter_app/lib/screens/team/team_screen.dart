import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/member_service.dart';

class TeamScreen extends StatefulWidget {
  final UserRole currentUserRole;
  const TeamScreen({super.key, required this.currentUserRole});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _memberService = MemberService();
  List<Profile> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final members = await _memberService.fetchOrgMembers();
    setState(() {
      _members = members;
      _loading = false;
    });
  }

  Future<void> _inviteDialog() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    String role = 'employee';
    String? error;
    bool saving = false;
    bool sent = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite employee'),
          content: SizedBox(
            width: 380,
            child: sent
                ? const Text('Invite sent — they will receive an email with sign-in instructions.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
                      const SizedBox(height: 10),
                      TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'employee', child: Text('Employee')),
                          DropdownMenuItem(value: 'manager', child: Text('Manager')),
                        ],
                        onChanged: (v) => setDialogState(() => role = v ?? 'employee'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ],
                  ),
          ),
          actions: sent
              ? [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))]
              : [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (emailController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                              setDialogState(() => error = 'Name and email are required');
                              return;
                            }
                            setDialogState(() => saving = true);
                            try {
                              await _memberService.inviteEmployee(
                                email: emailController.text.trim(),
                                fullName: nameController.text.trim(),
                                role: role,
                              );
                              setDialogState(() {
                                sent = true;
                                saving = false;
                              });
                            } catch (e) {
                              setDialogState(() {
                                error = 'Could not send invite: $e';
                                saving = false;
                              });
                            }
                          },
                    child: const Text('Send invite'),
                  ),
                ],
        ),
      ),
    );
    await _load();
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
              if (widget.currentUserRole.canManageTeam)
                ElevatedButton.icon(
                  onPressed: _inviteDialog,
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
