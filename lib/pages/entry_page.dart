// File: lib/pages/entry_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/models/journal_entry.dart';
import 'package:journal_app/pages/entries_page.dart';
import 'package:journal_app/pages/login_page.dart';
import 'package:journal_app/pages/settings_page.dart';
import 'package:journal_app/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key, this.title = "New Journal Entry"});

  final String title;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _storageService = StorageService();
  bool _isSignedIn = false; // Default to offline state
  String? _syncMessage;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _storageService.initializeFile();
    _loadLoginState();
  }

  void _loadLoginState() {
    setState(() {
      _isSignedIn = FirebaseAuth.instance.currentUser != null;
    });
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry saved!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _titleController.text.isEmpty
                ? 'Title cannot be empty.'
                : 'Content cannot be empty.',
          ),
        ),
      );
    }
  }

  Future<void> _syncEntries() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = 'Syncing to cloud...';
    });

    if (!_isSignedIn) {
      setState(() {
        _isSyncing = false;
        _syncMessage = 'Please sign in to sync';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in to sync')));
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _syncMessage = null;
          });
        }
      });
      return;
    }

    try {
      final success = await _storageService.syncToRealtimeDatabase().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (kDebugMode) {
            print('Sync operation timed out after 30 seconds');
          }
          return false;
        },
      );

      setState(() {
        _isSyncing = false;
        _syncMessage = success
            ? 'Synced to cloud!'
            : 'Cloud sync not available. Try again.';
      });
      if (!success && !mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloud sync not enabled or failed')),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncMessage = 'Cloud sync not available. Try again.';
      });
      if (kDebugMode) {
        print('Sync error: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud sync not enabled or failed')),
      );
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _syncMessage = null;
        });
      }
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isSignedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Flexible(
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
            if (_syncMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _syncMessage!,
                  style: TextStyle(
                    color:
                        _isSyncing ||
                            _syncMessage!.contains('failed') ||
                            _syncMessage!.contains('sign in')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEntry,
                    child: const Text('Save Entry'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSignedIn && !_isSyncing ? _syncEntries : null,
                    child: const Text('Sync'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Flexible(
                  child: TextButton(
                    onPressed: () async {
                      if (_isSignedIn) {
                        if (!mounted) return;
                        await FirebaseAuth.instance.signOut();
                        setState(() {
                          _isSignedIn = false;
                        });
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signed out')),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginPage(onLoginSuccess: _onLoginSuccess),
                          ),
                        );
                      }
                    },
                    child: Text(_isSignedIn ? 'Sign Out' : 'Login'),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EntriesPage(),
                        ),
                      );
                    },
                    child: const Text("Journal List"),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                    child: const Text("Settings"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
