import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../models/document.dart';
import '../../models/project.dart';
import '../../services/document_service.dart';
import '../../services/project_service.dart';
import '../../services/download_helper.dart'
    if (dart.library.html) '../../services/download_helper_web.dart';

class DocumentsScreen extends StatefulWidget {
  final String organizationId;
  const DocumentsScreen({super.key, required this.organizationId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _client = Supabase.instance.client;
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
    if (!mounted) return;
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

  bool _isImage(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
  }

  bool _isPdf(String fileName) => fileName.toLowerCase().endsWith('.pdf');

  /// معاينة الملف: الصور تتعرض جوا التطبيق، والباقي يتفتح في المتصفح
  Future<void> _openDocument(AppDocument doc) async {
    try {
      final url = await _documentService.getDownloadUrl(doc.storagePath);
      if (!mounted) return;

      final isImage = _isImage(doc.fileName);

      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(doc.fileName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: isImage
                      ? InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4,
                          child: Center(
                            child: Image.network(url, fit: BoxFit.contain),
                          ),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPdf(doc.fileName)
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.insert_drive_file_outlined,
                                  size: 64,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isPdf(doc.fileName)
                                      ? 'ملف PDF — دوس Open لعرضه في المتصفح.'
                                      : 'مفيش معاينة داخلية للنوع ده — دوس Open لعرضه في المتصفح.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _download(doc),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
      }
    }
  }

  /// تنزيل حقيقي للملف على الجهاز (Web + Windows)
    /// تنزيل حقيقي للملف على الجهاز (Web + Windows)
  Future<void> _download(AppDocument doc) async {
    try {
      final bytes =
          await _client.storage.from('documents').download(doc.storagePath);
      await saveFileToDevice(doc.fileName, bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
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
                        leading: Icon(
                          _isImage(d.fileName)
                              ? Icons.image_outlined
                              : (_isPdf(d.fileName)
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.insert_drive_file_outlined),
                        ),
                        title: Text(d.fileName),
                        subtitle: Text(
                          'Uploaded ${DateFormat('d MMM y, hh:mm a').format(d.uploadedAt.toLocal())}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download_outlined, size: 20),
                              tooltip: 'Download',
                              onPressed: () => _download(d),
                            ),
                          ],
                        ),
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