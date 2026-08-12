import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/create_organization_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/app_close_listener.dart'
    if (dart.library.html) 'services/app_close_listener_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // جلسة محفوظة => علّم المستخدم online
  if (Supabase.instance.client.auth.currentSession != null) {
    AuthService().setPresence('online');
  }

  // قفل تاب المتصفح => offline (ويب بس، على الويندوز الـ sign-out بيتكفل بيها)
  registerAppCloseListener(() {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id != null) {
      Supabase.instance.client
          .from('profiles')
          .update({'presence': 'offline'})
          .eq('id', id);
    }
  });

  runApp(const DeskFlowApp());
}

class DeskFlowApp extends StatelessWidget {
  const DeskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  late Future<Widget> _destination;

  @override
  void initState() {
    super.initState();
    _destination = _resolve();
  }

  Future<Widget> _resolve() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const LoginScreen();

    try {
      await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', session.user.id)
          .single();
      return const DashboardScreen();
    } catch (_) {
      return const CreateOrganizationScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _destination,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data!;
      },
    );
  }
}
