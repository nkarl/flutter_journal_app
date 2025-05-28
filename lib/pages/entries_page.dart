// File: lib/pages/entries_page.dart
import 'package:flutter/material.dart';
import 'package:journal_app/models/journal_entry.dart';
import 'package:journal_app/pages/entry_page.dart';
import 'package:journal_app/services/storage_service.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  final StorageService _storageService = StorageService();
  late Future<List<JournalEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshEntries();
  }

  void _refreshEntries() {
    setState(() {
      _entriesFuture = _storageService.readEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Journal Entries"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEntries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<JournalEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading entries'));
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No entries yet'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              _refreshEntries();
              // Wait for the future to complete to satisfy RefreshIndicator
              await _entriesFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    title: Text(entry.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.content.length > 50
                              ? '${entry.content.substring(0, 50)}...'
                              : entry.content,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    // Delete button (unchanged, ready for your implementation)
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => {
                        // TODO: implement DELETE button for each entry
                        /* _deleteEntry(entry.entryId, entry.title) */
                      },
                      tooltip: 'Delete entry',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // the floating + button to quickly go back to the entry screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).pop(MaterialPageRoute(builder: (context) => const EntryPage()));
        },
        tooltip: "Add New Entry",
        child: const Icon(Icons.add),
      ),
    );
  }
}
