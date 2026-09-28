import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/todo.dart';

class TodoService {
  final String url = "${ApiConfig.baseUrl}/todos";

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<List<Todo>> getTodos() async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Todo.fromJson(json)).toList();
    }
    throw Exception("Failed to load todos (${response.statusCode}): ${response.body}");
  }

  Future<List<Todo>> getTodosByProfile(int profileId) async {
    final response = await http
        .get(Uri.parse("$url/profile/$profileId"), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Todo.fromJson(json)).toList();
    }
    throw Exception("Failed to load todos for profile $profileId (${response.statusCode}): ${response.body}");
  }

  Future<Todo> createTodo(Todo todo) async {
    debugPrint("TodoService: POST $url body: ${jsonEncode(todo.toJson())}");
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(todo.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint("TodoService: POST response ${response.statusCode}: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Todo.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create todo (${response.statusCode}): ${response.body}");
  }

  Future<Todo> updateTodo(int id, Todo todo) async {
    final response = await http
        .put(
          Uri.parse("$url/$id"),
          headers: _headers,
          body: jsonEncode(todo.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Todo.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to update todo (${response.statusCode}): ${response.body}");
  }

  Future<void> deleteTodo(int id) async {
    final response = await http
        .delete(Uri.parse("$url/$id"), headers: _headers)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete todo (${response.statusCode}): ${response.body}");
    }
  }
}
