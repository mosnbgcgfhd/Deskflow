import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/activity_item.dart';
import '../../models/profile.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
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
  final _memberService = MemberService();
  final _client = Supabase.instance.client;

  Profile? _profile;
  List<Profile> _orgMembers = [];
  Map<String, String> _nameMap = {};
  List<ActivityItem> _activity = [];
  RealtimeChannel? _activityChannel;
  String _route = 'dashboard';

  int _projectCount = 0;
  int _taskCount = 0;
  int _overdueCount = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _authService.fetchMyProfile();
    final members = await _memberService.fetchOrgMembers();
    final nameMap = {for (final m in members) m.id: m.fullName};
    final activity = await _activityService.fetchRecent();

    // Real counts — no placeholder "—" values. Overdue = due_date in the
    // past and not yet Done.
    final projectsRes = await _client
        .from('projects')
        .select('id')
        .eq('organization_id', profile.organizationId)
        .count(CountOption.exact);
    final tasksRes = await _client
        .from('tasks')
        .select('id')
        .eq('organization_id', profile.organizationId)
        .count(CountOption.exact);
    final overdueRes = await _client
        .from('tasks')
        .select('id')
        .eq('organization_id', profile.organizationId)
        .neq('status', 'done')
        .lt('due_date', DateTime.now().toIso8601String().substring(0, 10))
        .count(CountOption.exact);

    setState(() {
      _profile = profile;
      _orgMembers = members;
      _nameMap = nameMap;
      _activity = activity;
      _projectCount = projectsRes.count;
      _taskCount = tasksRes.count;
      _overdueCount = overdueRes.count;
      _loading = false;
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

  String get _routeTitle {
    switch (_route) {
      case 'projects':
        return 'Projects';
      case 'team':
        return 'Team';
      case 'documents':
        return 'Documents';
      case 'activity':
        return 'Activity';
      case 'reports':
        return 'Reports';
      default:
        return 'Dashboard';
    }
  }

  Widget _bodyFor(String route) {
    final profile = _profile!;
    switch (route) {
      case 'projects':
        return ProjectsScreen(organizationId: profile.organizationId, orgMembers: _orgMembers);
      case 'team':
        return TeamScreen(currentUserRole: profile.role);
      case 'documents':
        return DocumentsScreen(organizationId: profile.organizationId);
      case 'activity':
        return ActivityLogScreen(nameMap: _nameMap);
      case 'reports':
        return ReportsScreen(organizationId: profile.organizationId, orgMembers: _orgMembers);
      default:
        return _dashboardBody();
    }
  }

  Widget _dashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good morning, ${_profile!.fullName}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Projects', value: '$_projectCount', icon: Icons.folder_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: StatCard(label: 'Tasks', value: '$_taskCount', icon: Icons.check_circle_outline)),
              const SizedBox(width: 12),
              Expanded(
                  child: StatCard(
                      label: 'Members',
                      value: '${_orgMembers.length}',
                      icon: Icons.people_outline,
                      accent: AppTheme.success)),
              const SizedBox(width: 12),
              Expanded(
                  child: StatCard(
                      label: 'Overdue',
                      value: '$_overdueCount',
                      icon: Icons.warning_amber_outlined,
                      accent: AppTheme.danger)),
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
                                title: Text(a.describe(_nameMap[a.actorId] ?? 'Someone')),
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
    if (_loading || _profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppShell(
      currentRoute: _route,
      title: _routeTitle,
      onNavigate: (r) => setState(() => _route = r),
      child: _bodyFor(_route),
    );
  }
}
