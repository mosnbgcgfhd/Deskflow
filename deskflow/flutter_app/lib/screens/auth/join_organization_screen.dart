import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart';

class JoinOrganizationScreen extends StatefulWidget {
  const JoinOrganizationScreen({super.key});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _client = Supabase.instance.client;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _join() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 1) Create the auth account (email confirmation must be OFF)
      await _client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2) Find the pending invite for this email
      final email = _emailController.text.trim().toLowerCase();
      final invites =
          await _client.from('invites').select().eq('email', email).limit(1);
      if ((invites as List).isEmpty) {
        throw Exception('No invite found for this email. Ask your admin to invite you first.');
      }
      final invite = invites.first as Map<String, dynamic>;

      // 3) Create the profile inside the inviting organization
      await _client.from('profiles').insert({
        'id': _client.auth.currentUser!.id,
        'organization_id': invite['organization_id'],
        'full_name': _fullNameController.text.trim(),
        'role': invite['role'],
      });

      // 4) Consume the invite
      await _client.from('invites').delete().eq('id', invite['id']);

      // 5) Mark online and enter
      await _client
          .from('profiles')
          .update({'presence': 'online'})
          .eq('id', _client.auth.currentUser!.id);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Could not join: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Organization')),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Your full name')),
                  const SizedBox(height: 14),
                  TextField(
                      controller: _emailController,
                      decoration:
                          const InputDecoration(labelText: 'Email (the one you were invited with)')),
                  const SizedBox(height: 14),
                  TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password')),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _join,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Join Organization'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}