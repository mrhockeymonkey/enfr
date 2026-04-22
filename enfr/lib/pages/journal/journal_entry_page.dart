import 'package:enfr/models/journal_entry.dart';
import 'package:enfr/services/journal_service.dart';
import 'package:flutter/material.dart';

class JournalEntryPage extends StatefulWidget {
  final JournalEntry? entry;

  const JournalEntryPage({super.key, this.entry});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _date;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _contentController = TextEditingController(text: e?.content ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final entries = await JournalService.loadEntries();
    final existing = widget.entry;
    final saved = JournalEntry(
      id: existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      title: _titleController.text.trim(),
      content: _contentController.text,
    );
    final idx = entries.indexWhere((e) => e.id == saved.id);
    if (idx >= 0) {
      entries[idx] = saved;
    } else {
      entries.add(saved);
    }
    await JournalService.saveEntries(entries);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.entry;
    if (existing == null) return;
    final entries = await JournalService.loadEntries();
    entries.removeWhere((e) => e.id == existing.id);
    await JournalService.saveEntries(entries);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_isEditing ? 'Edit entry' : 'New entry'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
