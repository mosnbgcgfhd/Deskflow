import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import '../tasks/kanban_board_screen.dart';

class ProjectsScreen extends StatefulWidget {
  final String organizationId;
  final List<Profile> orgMembers;
  const ProjectsScreen({super.key, required this.organizationId, required this.orgMembers});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _service = ProjectService();
  List<Project> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final projects = await _service.fetchProjects();
    setState(() {
      _projects = projects;
      _loading = false;
    });
  }

  Future<void> _createProjectDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? error;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        setDialogState(() => error = 'Project name is required');
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await _service.createProject(
                          organizationId: widget.organizationId,
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() {
                          error = 'Could not create project: $e';
                          saving = false;
                        });
                      }
                    },
              child: const Text('Create'),
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
              const Text('Projects', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _createProjectDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Project'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _projects.isEmpty
                ? const Center(child: Text('No projects yet.', style: TextStyle(color: AppTheme.textSecondary)))
                : GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: _projects
                        .map((p) => Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => KanbanBoardScreen(project: p, orgMembers: widget.orgMembers),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(p.description ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
