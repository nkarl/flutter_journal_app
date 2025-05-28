// File: lib/pages/entry_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/models/journal_entry.dart';
import 'package:journal_app/pages/entries_page.dart';
import 'package:journal_app/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class EntryPage extends StatefulWidget {
  // constructor
  const EntryPage({super.key, this.title = "New Journal Entry"});

  final String title;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _storageService.initializeFile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveEntry() async {
    if (_titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty) {
      final entry = JournalEntry(
        entryId: const Uuid().v4(),
        title: _titleController.text,
        content: _contentController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (kDebugMode) {
        print("Entry saved; ${entry.toJson()}");
      }
      await _storageService.saveEntry(entry);
      _titleController.clear();
      _contentController.clear();
    } else {
      if (kDebugMode) {
        if (_titleController.text.isEmpty) {
          print("Title cannot be empty.");
        } else if (_contentController.text.isEmpty) {
          print("Title cannot be empty.");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        // Padding is a layout widget. It takes a column of widgets as child
        // and add padding around it.
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Text field for Entry Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // Expanded Text Field for Entry Content
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: "Content",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16.0),

            // Button to save Entry
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Placeholder: Show a SnackBar to indicate saving (replace with actual save logic)
                  _saveEntry();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Entry saved!')));
                },
                child: const Text('Save Entry'),
              ),
            ),
            const SizedBox(height: 16.0),

            // a row of buttons for navigating to the journal list, login and settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    /*
                        TODO: implement cloud Firebase integration
                     */
                  },
                  child: const Text("Login"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EntriesPage(),
                      ),
                    );
                  },
                  child: const Text("Journal List"),
                ),
                TextButton(
                  onPressed: () {
                    /*
                        TODO: implement based on app features
                     */
                  },
                  child: const Text("Settings"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
