import 'package:flutter/material.dart';
import '../../services/task_service.dart';

class CreateTaskDialog extends StatefulWidget {
  final String organizationId;
  final String projectId;
  const CreateTaskDialog({super.key, required this.organizationId, required this.projectId});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _taskService = TaskService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  bool _saving = false;

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _taskService.createTask(
      organizationId: widget.organizationId,
      projectId: widget.projectId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Task'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: Text(_dueDate == null
                        ? 'Due date'
                        : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: const Text('Create Task'),
        ),
      ],
    );
  }
}
