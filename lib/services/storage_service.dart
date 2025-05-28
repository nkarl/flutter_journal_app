import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:journal_app/models/journal_entry.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  // Get the file path for `entries.json`
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    if (kDebugMode) {
      print(path);
    }
    return File('$path/entries.json');
  }

  // Initialize the JSON file with an empty list if it doesn't exist.
  Future<void> initializeFile() async {
    final file = await _localFile;
    if (!(await file.exists())) {
      await file.writeAsString(jsonEncode([]));
    }
  }

  // Save a journal entry to JSON.
  Future<void> saveEntry(JournalEntry entry) async {
    final file = await _localFile;
    final String contents = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(contents);
    jsonList.add(entry.toJson());
    await file.writeAsString(jsonEncode(jsonList));
    if (kDebugMode) {
      print('Saving to file path: ${file.path}');
      print(jsonList);
    }
  }

  // Read all journal entries from JSON.
  Future<List<JournalEntry>> readEntries() async {
    try {
      final file = await _localFile;
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => JournalEntry.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error reading entries from .json: $e');
      }
      return [];
    }
  }
}
