import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/document.dart';
import '../../models/project.dart';
import '../../services/document_service.dart';
import '../../services/project_service.dart';

class DocumentsScreen extends StatefulWidget {
  final String organizationId;
  const DocumentsScreen({super.key, required this.organizationId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _projectService = ProjectService();
  final _documentService = DocumentService();

  List<Project> _projects = [];
  Project? _selectedProject;
  List<AppDocument> _documents = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _projectService.fetchProjects();
    setState(() {
      _projects = projects;
      _selectedProject = projects.isNotEmpty ? projects.first : null;
      _loading = false;
    });
    if (_selectedProject != null) _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (_selectedProject == null) return;
    final docs = await _documentService.fetchForProject(_selectedProject!.id);
    setState(() => _documents = docs);
  }

  Future<void> _upload() async {
    if (_selectedProject == null) return;
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      await _documentService.upload(
        organizationId: widget.organizationId,
        projectId: _selectedProject!.id,
        fileName: file.name,
        bytes: file.bytes!,
      );
      await _loadDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDocument(AppDocument doc) async {
    final url = await _documentService.getDownloadUrl(doc.storagePath);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed link (valid 10 min): $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_projects.isEmpty) {
      return const Center(
        child: Text('Create a project first — documents belong to a project.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              DropdownButton<Project>(
                value: _selectedProject,
                items: _projects
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (p) {
                  setState(() => _selectedProject = p);
                  _loadDocuments();
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(_uploading ? 'Uploading...' : 'Upload'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _documents.isEmpty
                ? const Center(child: Text('No documents yet.', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    itemCount: _documents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = _documents[i];
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(d.fileName),
                        subtitle: Text('Uploaded ${d.uploadedAt.toLocal()}'),
                        trailing: const Icon(Icons.download_outlined),
                        onTap: () => _openDocument(d),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
