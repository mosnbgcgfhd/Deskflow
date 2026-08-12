import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';

/// First-run flow: sign up, then create the org (calling user becomes Admin).
class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  State<CreateOrganizationScreen> createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _authService = AuthService();
  final _client = Supabase.instance.client;

  final _orgNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _alreadySignedIn => _client.auth.currentSession != null;

  Future<void> _createOrganization() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // If they already have a session (e.g. they confirmed their email
      // link and came straight back here), skip signUp entirely — it
      // would just fail with "already registered".
      if (_alreadySignedIn) {
        await _authService.createOrganizationAndAdmin(
          orgName: _orgNameController.text.trim(),
          fullName: _fullNameController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        return;
      }

      final signUpRes = await _client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // If your Supabase project has "Confirm email" turned on (the
      // default), signUp() does NOT return an active session — the
      // user has to click the confirmation link first. Organization
      // creation needs auth.uid(), so it must wait until then.
      if (signUpRes.session == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = null;
        });
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirm your email'),
            content: const Text(
              "We've sent a confirmation link to your email. After you "
              'confirm, sign in normally — you\'ll be prompted to finish '
              'creating your organization on first sign-in.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      await _authService.createOrganizationAndAdmin(
        orgName: _orgNameController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Could not create organization: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Organization')),
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
                    controller: _orgNameController,
                    decoration: const InputDecoration(labelText: 'Company name'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Your full name'),
                  ),
                  if (!_alreadySignedIn) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _createOrganization,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create Organization'),
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
