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
    _storageService.initializeFile();
    _refreshEntries();
  }

  void _refreshEntries() {
    setState(() {
      _entriesFuture = _storageService.readEntries();
    });
  }

  Future<bool> _deleteEntry(String entryId, String title) async {
    final bool? isDeleting = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Entry"),
          content: Text("Are you sure you want to delete '$title'?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (isDeleting != true) return false;

    final success = await _storageService.deleteEntry(entryId);
    if (!mounted) return false;

    if (success) {
      _refreshEntries();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry "$title" deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete entry "$title"')),
      );
    }
    return success;
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
            return Center(
              child: Column(
                children: [
                  Text('Error loading entries'),
                  ElevatedButton(
                    onPressed: _refreshEntries,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
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
                  // wrapper fo each entry to swipe-to-delete
                  child: Dismissible(
                    key: Key(entry.entryId),
                    direction: DismissDirection.endToStart, // swipe RTL
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await _deleteEntry(entry.entryId, entry.title);
                    },
                    onDismissed: (_) => _refreshEntries(),
                    // actual entry
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
                        onPressed: () =>
                            _deleteEntry(entry.entryId, entry.title),
                        tooltip: 'Delete entry',
                      ),
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
          ).push(MaterialPageRoute(builder: (context) => const EntryPage()));
        },
        tooltip: "Add New Entry",
        child: const Icon(Icons.add),
      ),
    );
  }
}
