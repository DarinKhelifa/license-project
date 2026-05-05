import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../providers/auth_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class NoteItem {
  final String id;
  final String title;
  final String content;
  final DateTime? reminder;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    this.reminder,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'reminder': reminder?.toIso8601String(),
      };

  static NoteItem fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        reminder: json['reminder'] != null
            ? DateTime.parse(json['reminder'] as String)
            : null,
      );
}

class _NotesScreenState extends State<NotesScreen> {
  final List<NoteItem> _notes = [];
  late SharedPreferences _prefs;
  String? _storageKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPrefs());
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userId ?? 'anonymous';
    _storageKey = 'notes_$uid';
    _loadNotes();
  }

  void _loadNotes() {
    final raw = _prefs.getStringList(_storageKey ?? '') ?? [];
    setState(() {
      _notes.clear();
      for (final s in raw) {
        final m = json.decode(s) as Map<String, dynamic>;
        _notes.add(NoteItem.fromJson(m));
      }
    });
    _startReminderLoop();
  }

  Future<void> _saveNotes() async {
    final list = _notes.map((n) => json.encode(n.toJson())).toList();
    await _prefs.setStringList(_storageKey ?? '', list);
  }

  Future<void> _addOrEditNote({NoteItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    DateTime? reminder = existing?.reminder;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(reminder == null
                      ? 'No reminder'
                      : 'Reminder: ${reminder?.toLocal().toString().split('.').first}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: reminder ?? DateTime.now().add(const Duration(hours: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(reminder ?? DateTime.now()),
                      );
                      if (time == null) return;
                      setState(() {
                        reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    },
                    child: const Text('Set Reminder'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final content = contentController.text.trim();
                        if (title.isEmpty && content.isEmpty) return;

                        if (existing != null) {
                          final idx = _notes.indexWhere((n) => n.id == existing.id);
                          if (idx >= 0) {
                            _notes[idx] = NoteItem(
                              id: existing.id,
                              title: title,
                              content: content,
                              reminder: reminder,
                            );
                          }
                        } else {
                          final id = DateTime.now().millisecondsSinceEpoch.toString();
                          final note = NoteItem(id: id, title: title, content: content, reminder: reminder);
                          _notes.insert(0, note);
                        }

                        await _saveNotes();
                        if (mounted) Navigator.pop(ctx);
                        setState(() {});
                      },
                      child: Text(existing != null ? 'Save' : 'Add Note'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Timer? _reminderTimer;

  void _startReminderLoop() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final now = DateTime.now();
      for (final note in List<NoteItem>.from(_notes)) {
        if (note.reminder != null && note.reminder!.isBefore(now)) {
          // Show an in-app alert and/or SnackBar when a reminder is due
          if (!mounted) return;
          final idx = _notes.indexWhere((n) => n.id == note.id);

          // Clear reminder so we don't re-notify
          if (idx >= 0) {
            _notes[idx] = NoteItem(
              id: note.id,
              title: note.title,
              content: note.content,
              reminder: null,
            );
            await _saveNotes();
            setState(() {});
          }

          // Prefer showing a dialog if the app is foreground and the screen is visible
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(note.title.isEmpty ? 'Note reminder' : note.title),
                content: Text(note.content),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reminder: ${note.title.isEmpty ? 'Note' : note.title}')),
            );
          });
        }
      }
    });
  }

  Future<void> _deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveNotes();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No notes yet. Tap + to add a note.'),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (ctx, i) {
                  final n = _notes[i];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(n.title.isEmpty ? '(No title)' : n.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                          if (n.reminder != null) ...[
                            const SizedBox(height: 6),
                            Text('Reminder: ${n.reminder!.toLocal().toString().split('.').first}', style: const TextStyle(color: Colors.redAccent)),
                          ]
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await _addOrEditNote(existing: n);
                          } else if (v == 'delete') {
                            await _deleteNote(n.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }
}
