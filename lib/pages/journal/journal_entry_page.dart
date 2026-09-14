import 'package:enfr/models/correction.dart';
import 'package:enfr/models/journal_entry.dart';
import 'package:enfr/services/correction_service.dart';
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
  late String _id;
  bool _saving = false;
  List<Correction> _corrections = const [];

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _contentController = TextEditingController(text: e?.content ?? '');
    _date = e?.date ?? DateTime.now();
    _id = e?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _corrections = e?.corrections ?? const [];
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

  Future<void> _persist(List<Correction> corrections) async {
    final entries = await JournalService.loadEntries();
    final saved = JournalEntry(
      id: _id,
      date: _date,
      title: _titleController.text.trim(),
      content: _contentController.text,
      corrections: corrections,
    );
    final idx = entries.indexWhere((e) => e.id == saved.id);
    if (idx >= 0) {
      entries[idx] = saved;
    } else {
      entries.add(saved);
    }
    await JournalService.saveEntries(entries);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    await _persist(_corrections);

    try {
      final fresh = await CorrectionService.checkEntry(
        _contentController.text,
        previous: _corrections,
      );
      await _persist(fresh);
      if (!mounted) return;
      setState(() => _corrections = fresh);
      _showCorrectionsSheet();
    } on MissingApiKeyException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add your Mistral API key in Settings first')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't check entry: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.entry;
    if (existing == null) return;
    final entries = await JournalService.loadEntries();
    entries.removeWhere((e) => e.id == existing.id);
    await JournalService.saveEntries(entries);
    if (mounted) Navigator.of(context).pop();
  }

  void _showCorrectionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        if (_corrections.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Looks good — no corrections!',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }
        final active = _corrections.active;
        final fixed = _corrections.fixed;
        final rows = <Widget>[];
        if (active.isNotEmpty) {
          rows.add(_sectionHeader('Active (${active.length})'));
          rows.addAll(active.map(_activeCard));
        }
        if (fixed.isNotEmpty) {
          rows.add(_sectionHeader('Fixed (${fixed.length})'));
          rows.addAll(fixed.map(_fixedCard));
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) => ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            itemBuilder: (ctx, i) => rows[i],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  Widget _activeCard(Correction c) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.originalText,
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.red.shade700,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Icon(Icons.arrow_downward, size: 16),
              ),
              Text(
                c.suggestedText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _fixedCard(Correction c) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(Icons.check_circle,
                    size: 18, color: Colors.green.shade600),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.originalText,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Icon(Icons.arrow_downward,
                          size: 14, color: Colors.grey),
                    ),
                    Text(
                      c.suggestedText,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final activeCount = _corrections.active.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_isEditing ? 'Edit entry' : 'New entry'),
        actions: [
          if (_corrections.isNotEmpty)
            IconButton(
              icon: activeCount > 0
                  ? Badge(
                      label: Text('$activeCount'),
                      child: const Icon(Icons.rule),
                    )
                  : const Icon(Icons.rule),
              onPressed: _showCorrectionsSheet,
              tooltip: 'View corrections',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
              tooltip: 'Delete',
            ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _saving ? null : _save,
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
