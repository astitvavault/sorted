import 'package:flutter/material.dart';
import 'package:todo_app/data/database.dart';
import 'package:todo_app/models/note.dart';
import 'package:todo_app/services/note_service.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  ToDoDatabase db = ToDoDatabase();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final NoteService _noteService = NoteService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    await db.loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addNote() {
    _titleController.clear();
    _contentController.clear();
    showDialog(
      context: context,
      builder: (context) => _buildNoteDialog(),
    );
  }

  void _editNote(int index) {
    _titleController.text = db.notesList[index][0];
    _contentController.text = db.notesList[index][1];
    showDialog(
      context: context,
      builder: (context) => _buildNoteDialog(index: index),
    );
  }

  void _deleteNote(int index) async {
    int? id = db.notesList[index].length > 3 ? db.notesList[index][3] : null;
    setState(() {
      db.notesList.removeAt(index);
    });
    await db.updateData();
    if (id != null) {
      try {
        await _noteService.deleteNote(id);
      } catch (e) {
        print("Failed to delete note from backend: $e");
      }
    }
  }

  Widget _buildNoteDialog({int? index}) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index == null ? "New Note" : "Edit Note",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: _inputDecoration("Title"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                style: const TextStyle(color: Colors.white70),
                maxLines: 8,
                decoration: _inputDecoration("Content"),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _titleController.clear();
                      _contentController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      String title = _titleController.text.trim();
                      String content = _contentController.text.trim();

                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Title cannot be empty")),
                        );
                        return;
                      }

                      int? profileId = db.profileData["id"];
                      int localId = DateTime.now().millisecondsSinceEpoch % 2147483647;

                      if (index == null) {
                        // Save locally first
                        var newNoteItem = [title, content, "", localId];
                        setState(() {
                          db.notesList.insert(0, newNoteItem);
                        });
                        await db.updateData();

                        // Sync with backend if profile exists
                        if (profileId != null) {
                          try {
                            Note newNote = Note(title: title, content: content, profileId: profileId);
                            Note created = await _noteService.createNote(newNote);
                            final createdId = created.id;
                            if (createdId != null) {
                              newNoteItem[3] = createdId;
                              await db.updateData();
                            }
                          } catch (e) {
                            print("Backend note creation error (saved locally): $e");
                          }
                        }
                      } else {
                        int noteId = db.notesList[index].length > 3 ? db.notesList[index][3] : localId;
                        setState(() {
                          db.notesList[index] = [title, content, "", noteId];
                        });
                        await db.updateData();

                        if (profileId != null && noteId != localId) {
                          try {
                            Note updatedNote = Note(id: noteId, title: title, content: content, profileId: profileId);
                            await _noteService.updateNote(noteId, updatedNote);
                          } catch (e) {
                            print("Backend note update error (saved locally): $e");
                          }
                        }
                      }
                      
                      _titleController.clear();
                      _contentController.clear();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4B483),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD4B483), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4B483))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Notes", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: db.notesList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_note, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    "No notes yet.",
                    style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap + to create a note",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemCount: db.notesList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _editNote(index),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                db.notesList[index][0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _deleteNote(index),
                              child: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            db.notesList[index][1],
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: const Color(0xFFD4B483),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
