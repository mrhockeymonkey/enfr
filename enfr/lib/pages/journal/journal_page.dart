import 'package:enfr/models/journal_entry.dart';
import 'package:enfr/pages/journal/journal_entry_page.dart';
import 'package:enfr/services/journal_service.dart';
import 'package:flutter/material.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<JournalEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await JournalService.loadEntries();
    entries.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _openEntry(JournalEntry? entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEntryPage(entry: entry),
      ),
    );
    await _load();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Journal'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Text(
                    'No journal entries yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    return ListTile(
                      title: Text(
                        e.title.isEmpty ? '(untitled)' : e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatDate(e.date)),
                      onTap: () => _openEntry(e),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEntry(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
