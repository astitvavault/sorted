import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/todo.dart';

class TodoService {
  final String url = "${ApiConfig.baseUrl}/todos";

  Future<List<Todo>> getTodos() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Todo.fromJson(json)).toList();
    }
    throw Exception("Failed to load todos");
  }

  Future<List<Todo>> getTodosByProfile(int profileId) async {
    final response = await http.get(Uri.parse("$url/profile/$profileId"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Todo.fromJson(json)).toList();
    }
    throw Exception("Failed to load todos for profile $profileId");
  }

  Future<Todo> createTodo(Todo todo) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 201) return Todo.fromJson(jsonDecode(response.body));
    throw Exception("Failed to create todo");
  }

  Future<Todo> updateTodo(int id, Todo todo) async {
    final response = await http.put(
      Uri.parse("$url/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 200) return Todo.fromJson(jsonDecode(response.body));
    throw Exception("Failed to update todo");
  }

  Future<void> deleteTodo(int id) async {
    final response = await http.delete(Uri.parse("$url/$id"));
    if (response.statusCode != 204) throw Exception("Failed to delete todo");
  }
}
