import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/reminder.dart';

class ReminderService {
  final String url = "${ApiConfig.baseUrl}/reminders";

  Future<List<Reminder>> getReminders() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    }
    throw Exception("Failed to load reminders");
  }

  Future<List<Reminder>> getRemindersByProfile(int profileId) async {
    final response = await http.get(Uri.parse("$url/profile/$profileId"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    }
    throw Exception("Failed to load reminders for profile $profileId");
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(reminder.toJson()),
    );
    if (response.statusCode == 201) return Reminder.fromJson(jsonDecode(response.body));
    throw Exception("Failed to create reminder");
  }

  Future<Reminder> updateReminder(int id, Reminder reminder) async {
    final response = await http.put(
      Uri.parse("$url/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(reminder.toJson()),
    );
    if (response.statusCode == 200) return Reminder.fromJson(jsonDecode(response.body));
    throw Exception("Failed to update reminder");
  }

  Future<void> deleteReminder(int id) async {
    final response = await http.delete(Uri.parse("$url/$id"));
    if (response.statusCode != 204) throw Exception("Failed to delete reminder");
  }
}
