// File: lib/pages/my_home_page.dart
import 'package:flutter/material.dart';
import 'package:journal_app/pages/entries_page.dart';

class MyHomePage extends StatefulWidget {
  // constructor
  const MyHomePage({super.key, this.title = "New Journal Entry"});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // Expanded Text Field for Entry Content
            Expanded(
              child: TextField(
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EntriesPage(),
                      ),
                    );
                  },
                  child: const Text("Journal List"),
                ),
                TextButton(onPressed: () {}, child: const Text("Login")),
                TextButton(onPressed: () {}, child: const Text("Settings")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
