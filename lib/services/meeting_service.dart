import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/meeting.dart';

class MeetingService {
  final String url = "${ApiConfig.baseUrl}/meetings";

  Future<List<Meeting>> getMeetings() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Meeting.fromJson(json)).toList();
    }
    throw Exception("Failed to load meetings");
  }

  Future<List<Meeting>> getMeetingsByProfile(int profileId) async {
    final response = await http.get(Uri.parse("$url/profile/$profileId"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Meeting.fromJson(json)).toList();
    }
    throw Exception("Failed to load meetings for profile $profileId");
  }

  Future<Meeting> createMeeting(Meeting meeting) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(meeting.toJson()),
    );
    if (response.statusCode == 201) return Meeting.fromJson(jsonDecode(response.body));
    throw Exception("Failed to create meeting");
  }

  Future<Meeting> updateMeeting(int id, Meeting meeting) async {
    final response = await http.put(
      Uri.parse("$url/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(meeting.toJson()),
    );
    if (response.statusCode == 200) return Meeting.fromJson(jsonDecode(response.body));
    throw Exception("Failed to update meeting");
  }

  Future<void> deleteMeeting(int id) async {
    final response = await http.delete(Uri.parse("$url/$id"));
    if (response.statusCode != 204) throw Exception("Failed to delete meeting");
  }
}
