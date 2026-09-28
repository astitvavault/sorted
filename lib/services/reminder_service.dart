import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/reminder.dart';

class ReminderService {
  final String url = "${ApiConfig.baseUrl}/reminders";

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<List<Reminder>> getReminders() async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    }
    throw Exception("Failed to load reminders (${response.statusCode}): ${response.body}");
  }

  Future<List<Reminder>> getRemindersByProfile(int profileId) async {
    final response = await http
        .get(Uri.parse("$url/profile/$profileId"), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    }
    throw Exception("Failed to load reminders for profile $profileId (${response.statusCode}): ${response.body}");
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    debugPrint("ReminderService: POST $url body: ${jsonEncode(reminder.toJson())}");
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(reminder.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint("ReminderService: POST response ${response.statusCode}: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reminder.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create reminder (${response.statusCode}): ${response.body}");
  }

  Future<Reminder> updateReminder(int id, Reminder reminder) async {
    final response = await http
        .put(
          Uri.parse("$url/$id"),
          headers: _headers,
          body: jsonEncode(reminder.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reminder.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to update reminder (${response.statusCode}): ${response.body}");
  }

  Future<void> deleteReminder(int id) async {
    final response = await http
        .delete(Uri.parse("$url/$id"), headers: _headers)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete reminder (${response.statusCode}): ${response.body}");
    }
  }
}
