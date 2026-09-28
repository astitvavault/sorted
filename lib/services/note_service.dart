import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/note.dart';

class NoteService {
  final String url = "${ApiConfig.baseUrl}/notes";

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<List<Note>> getNotes() async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    }
    throw Exception("Failed to load notes (${response.statusCode}): ${response.body}");
  }

  Future<List<Note>> getNotesByProfile(int profileId) async {
    final response = await http
        .get(Uri.parse("$url/profile/$profileId"), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    }
    throw Exception("Failed to load notes for profile $profileId (${response.statusCode}): ${response.body}");
  }

  Future<Note> createNote(Note note) async {
    debugPrint("NoteService: POST $url body: ${jsonEncode(note.toJson())}");
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(note.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint("NoteService: POST response ${response.statusCode}: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Note.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create note (${response.statusCode}): ${response.body}");
  }

  Future<Note> updateNote(int id, Note note) async {
    final response = await http
        .put(
          Uri.parse("$url/$id"),
          headers: _headers,
          body: jsonEncode(note.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Note.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to update note (${response.statusCode}): ${response.body}");
  }

  Future<void> deleteNote(int id) async {
    final response = await http
        .delete(Uri.parse("$url/$id"), headers: _headers)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete note (${response.statusCode}): ${response.body}");
    }
  }
}
