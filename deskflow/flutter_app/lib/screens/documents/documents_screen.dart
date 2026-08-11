import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/document.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _client = Supabase.instance.client;
  List<AppDocument> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _client.from('documents').select().order('uploaded_at', ascending: false);
    setState(() {
      _documents = (rows as List).map((r) => AppDocument.fromMap(r)).toList();
      _loading = false;
    });
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
              const Text('Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {}, // opens file_picker, uploads to Supabase Storage bucket "documents"
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload'),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
