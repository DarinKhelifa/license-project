import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/maintenance_bottom_nav_bar.dart';

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

  static NoteItem fromMap(Map<String, dynamic> map) => NoteItem(
        id: (map['id'] ?? map['_id']).toString(),
        title: (map['title'] ?? '').toString(),
        content: (map['content'] ?? '').toString(),
        reminder: map['reminder'] != null && map['reminder'].toString().isNotEmpty
            ? DateTime.tryParse(map['reminder'].toString())
            : null,
      );
}

class _NotesScreenState extends State<NotesScreen> {
  final List<NoteItem> _notes = [];
  SharedPreferences? _prefs;
  String? _storageKey;
  Timer? _reminderTimer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotes());
  }

  Future<void> _ensureStorageKey() async {
    _prefs ??= await SharedPreferences.getInstance();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userId ?? 'anonymous';
    _storageKey = 'notes_$uid';
  }

  List<NoteItem> _readCachedNotes() {
    final raw = _prefs?.getStringList(_storageKey ?? '') ?? [];
    final cached = <NoteItem>[];

    for (final value in raw) {
      try {
        final decoded = json.decode(value) as Map<String, dynamic>;
        cached.add(NoteItem.fromMap(decoded));
      } catch (_) {
        continue;
      }
    }

    return cached;
  }

  Future<void> _saveCachedNotes() async {
    if (_prefs == null) return;
    final list = _notes.map((note) => json.encode(note.toJson())).toList();
    await _prefs!.setStringList(_storageKey ?? '', list);
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _ensureStorageKey();

      List<NoteItem> loadedNotes = [];
      try {
        final remoteNotes = await ApiService.getSecurityNotes();
        loadedNotes = remoteNotes.map(NoteItem.fromMap).toList();

        if (loadedNotes.isEmpty) {
          final cachedNotes = _readCachedNotes();
          if (cachedNotes.isNotEmpty) {
            for (final note in cachedNotes) {
              await ApiService.createSecurityNote(
                title: note.title,
                content: note.content,
                reminder: note.reminder,
              );
            }

            final migratedNotes = await ApiService.getSecurityNotes();
            loadedNotes = migratedNotes.map(NoteItem.fromMap).toList();
          }
        }
      } catch (error) {
        loadedNotes = _readCachedNotes();
        if (loadedNotes.isEmpty) {
          throw error;
        }
      }

      _notes
        ..clear()
        ..addAll(loadedNotes);
      await _saveCachedNotes();
      _startReminderLoop();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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
                    child: Text(
                      reminder == null
                          ? 'No reminder'
                          : 'Reminder: ${reminder?.toLocal().toString().split('.').first}',
                    ),
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

                        try {
                          if (existing != null) {
                            await ApiService.updateSecurityNote(
                              noteId: existing.id,
                              title: title,
                              content: content,
                              reminder: reminder,
                            );
                          } else {
                            await ApiService.createSecurityNote(
                              title: title,
                              content: content,
                              reminder: reminder,
                            );
                          }

                          if (!mounted) return;
                          Navigator.pop(ctx);
                          await _loadNotes();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existing != null ? 'Note updated' : 'Note saved'),
                            ),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save note: $error'),
                            ),
                          );
                        }
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

  void _startReminderLoop() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final now = DateTime.now();
      for (final note in List<NoteItem>.from(_notes)) {
        if (note.reminder != null && note.reminder!.isBefore(now)) {
          if (!mounted) return;

          final idx = _notes.indexWhere((n) => n.id == note.id);
          if (idx >= 0) {
            _notes[idx] = NoteItem(
              id: note.id,
              title: note.title,
              content: note.content,
              reminder: null,
            );
            await _saveCachedNotes();
            try {
              await ApiService.updateSecurityNote(
                noteId: note.id,
                title: note.title,
                content: note.content,
                reminder: null,
              );
            } catch (_) {}
            if (mounted) setState(() {});
          }

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
    await ApiService.deleteSecurityNote(id);
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isMaintenance = (auth.user?['role'] ?? 'resident').toString() == 'maintenance';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: true,
      ),
      bottomNavigationBar: isMaintenance ? const MaintenanceBottomNavBar(currentIndex: 1) : null,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? 'No notes yet. Tap + to add a note.',
                          textAlign: TextAlign.center,
                        ),
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
                                Text(
                                  'Reminder: ${n.reminder!.toLocal().toString().split('.').first}',
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
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
