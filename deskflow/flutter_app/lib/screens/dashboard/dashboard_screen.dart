import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/activity_item.dart';
import '../../models/profile.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/stat_card.dart';
import '../projects/projects_screen.dart';
import '../team/team_screen.dart';
import '../documents/documents_screen.dart';
import '../activity/activity_log_screen.dart';
import '../reports/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _activityService = ActivityService();

  Profile? _profile;
  List<ActivityItem> _activity = [];
  RealtimeChannel? _activityChannel;
  String _route = 'dashboard';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _authService.fetchMyProfile();
    final activity = await _activityService.fetchRecent();
    setState(() {
      _profile = profile;
      _activity = activity;
    });

    // Live feed: new activity from any teammate appears instantly.
    _activityChannel = _activityService.subscribeToOrgActivity(
      profile.organizationId,
      (item) => setState(() => _activity = [item, ..._activity]),
    );
  }

  @override
  void dispose() {
    _activityChannel?.unsubscribe();
    super.dispose();
  }

  Widget _bodyFor(String route) {
    switch (route) {
      case 'projects':
        return const ProjectsScreen();
      case 'team':
        return const TeamScreen();
      case 'documents':
        return const DocumentsScreen();
      case 'activity':
        return const ActivityLogScreen();
      case 'reports':
        return const ReportsScreen();
      default:
        return _dashboardBody();
    }
  }

  Widget _dashboardBody() {
    if (_profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good morning, ${_profile!.fullName}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: StatCard(label: 'Projects', value: '—', icon: Icons.folder_outlined)),
              SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Tasks', value: '—', icon: Icons.check_circle_outline)),
              SizedBox(width: 12),
              Expanded(
                  child: StatCard(
                      label: 'Members', value: '—', icon: Icons.people_outline, accent: AppTheme.success)),
              SizedBox(width: 12),
              Expanded(
                  child: StatCard(
                      label: 'Overdue', value: '—', icon: Icons.warning_amber_outlined, accent: AppTheme.danger)),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _activity.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No activity yet.', style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  : Column(
                      children: _activity
                          .take(10)
                          .map((a) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.circle, size: 8, color: AppTheme.primary),
                                title: Text(a.describe('Someone')),
                                trailing: Text(
                                  '${a.createdAt.hour.toString().padLeft(2, '0')}:${a.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: _route,
      onNavigate: (r) => setState(() => _route = r),
      child: _bodyFor(_route),
    );
  }
}
