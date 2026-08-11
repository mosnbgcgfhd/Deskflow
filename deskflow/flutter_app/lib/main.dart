import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
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
      home: Supabase.instance.client.auth.currentSession != null
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}
