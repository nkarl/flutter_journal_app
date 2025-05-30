// File: lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
      print(await file.readAsString(encoding: utf8));
      print(jsonList);
    }
  }

  // Read all journal entries from JSON.
  // File: lib/services/storage_service.dart
  // Replace readEntries method
  Future<List<JournalEntry>> readEntries() async {
    try {
      final file = await _localFile;
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      List<JournalEntry> localEntries = jsonList
          .map((json) => JournalEntry.fromJson(json))
          .toList();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final database = FirebaseDatabase.instance;
          final ref = database.ref('users/${user.uid}/entries');
          final snapshot = await ref.get();
          if (kDebugMode) {
            print('Realtime Database snapshot value: ${snapshot.value}');
          }
          if (snapshot.exists && snapshot.value != null) {
            // Convert snapshot.value to Map<String, dynamic>
            final cloudData = (snapshot.value as Map).cast<String, dynamic>();
            final cloudTimestamp = DateTime.parse(
              cloudData['timestamp'] as String? ?? '1970-01-01T00:00:00Z',
            );
            final localTimestamp = await _getLocalTimestamp();

            if (cloudTimestamp.isAfter(localTimestamp)) {
              final cloudEntries =
                  (cloudData['entries'] as List<dynamic>?)
                      ?.map(
                        (json) =>
                            JournalEntry.fromJson(json as Map<String, dynamic>),
                      )
                      .toList() ??
                  [];
              localEntries = cloudEntries;
              await file.writeAsString(
                jsonEncode(cloudEntries.map((e) => e.toJson()).toList()),
              );
              if (kDebugMode) {
                print(
                  'Restored ${localEntries.length} entries from Realtime Database',
                );
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Realtime Database read error: $e');
          }
        }
      }
      return localEntries;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading entries from .json: $e');
      }
      return [];
    }
  }

  // Delete a journal entry by Id.
  Future<bool> deleteEntry(String entryId) async {
    var success = false;
    try {
      final file = await _localFile;
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      // needed to check if the entry is actually deleted.
      final int previousLength = jsonList.length;

      // find and remove the entry with matching Id
      jsonList.removeWhere((json) => json['entryId'] == entryId);

      // check if entry is actually deleted.
      if (jsonList.length < previousLength) {
        await file.writeAsString(jsonEncode(jsonList));
        success = true;
      }
      if (kDebugMode) {
        success
            ? print("Entry deleted: $entryId")
            : print("Entry not found: $entryId");
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting entry: $e");
      }
      return false;
    }
  }

  Future<bool> syncToRealtimeDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final database = FirebaseDatabase.instance; // Lazy initialization
        final file = await _localFile;
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        await database.ref('users/${user.uid}/entries').set({
          'entries': jsonList,
          'timestamp': DateTime.now().toIso8601String(),
        });
        if (kDebugMode) {
          print('Synced JSON to Realtime Database for user ${user.uid}');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('Realtime Database sync error: $e');
        }
        return false;
      }
    }
    return false;
  }

  Future<DateTime> _getLocalTimestamp() async {
    final file = await _localFile;
    if (await file.exists()) {
      final stat = await file.stat();
      return stat.modified;
    }
    return DateTime(1970);
  }
}
