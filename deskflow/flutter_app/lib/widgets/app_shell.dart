import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import 'notification_bell.dart';

/// Persistent left sidebar + top bar shared by every authenticated
/// screen — mirrors the section list from the product spec.
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String title;
  final void Function(String route) onNavigate;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onNavigate,
    this.title = '',
  });

  static const _items = [
    ('dashboard', Icons.dashboard_outlined, 'Dashboard'),
    ('projects', Icons.folder_outlined, 'Projects'),
    ('team', Icons.people_outline, 'Team'),
    ('documents', Icons.description_outlined, 'Documents'),
    ('activity', Icons.history, 'Activity'),
    ('reports', Icons.bar_chart_outlined, 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('DeskFlow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                for (final item in _items)
                  ListTile(
                    leading: Icon(item.$2, size: 20),
                    title: Text(item.$3),
                    selected: currentRoute == item.$1,
                    selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
                    onTap: () => onNavigate(item.$1),
                  ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, size: 20),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const NotificationBell(),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
