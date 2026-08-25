import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/note.dart';

class NoteService {
  final String url = "${ApiConfig.baseUrl}/notes";

  Future<List<Note>> getNotes() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    }
    throw Exception("Failed to load notes");
  }

  Future<List<Note>> getNotesByProfile(int profileId) async {
    final response = await http.get(Uri.parse("$url/profile/$profileId"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    }
    throw Exception("Failed to load notes for profile $profileId");
  }

  Future<Note> createNote(Note note) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(note.toJson()),
    );
    if (response.statusCode == 201) return Note.fromJson(jsonDecode(response.body));
    throw Exception("Failed to create note");
  }

  Future<Note> updateNote(int id, Note note) async {
    final response = await http.put(
      Uri.parse("$url/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(note.toJson()),
    );
    if (response.statusCode == 200) return Note.fromJson(jsonDecode(response.body));
    throw Exception("Failed to update note");
  }

  Future<void> deleteNote(int id) async {
    final response = await http.delete(Uri.parse("$url/$id"));
    if (response.statusCode != 204) throw Exception("Failed to delete note");
  }
}
