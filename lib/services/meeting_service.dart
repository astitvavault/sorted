import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/meeting.dart';

class MeetingService {
  final String url = "${ApiConfig.baseUrl}/meetings";

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<List<Meeting>> getMeetings() async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Meeting.fromJson(json)).toList();
    }
    throw Exception("Failed to load meetings (${response.statusCode}): ${response.body}");
  }

  Future<List<Meeting>> getMeetingsByProfile(int profileId) async {
    final response = await http
        .get(Uri.parse("$url/profile/$profileId"), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Meeting.fromJson(json)).toList();
    }
    throw Exception("Failed to load meetings for profile $profileId (${response.statusCode}): ${response.body}");
  }

  Future<Meeting> createMeeting(Meeting meeting) async {
    debugPrint("MeetingService: POST $url body: ${jsonEncode(meeting.toJson())}");
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(meeting.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint("MeetingService: POST response ${response.statusCode}: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Meeting.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create meeting (${response.statusCode}): ${response.body}");
  }

  Future<Meeting> updateMeeting(int id, Meeting meeting) async {
    final response = await http
        .put(
          Uri.parse("$url/$id"),
          headers: _headers,
          body: jsonEncode(meeting.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Meeting.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to update meeting (${response.statusCode}): ${response.body}");
  }

  Future<void> deleteMeeting(int id) async {
    final response = await http
        .delete(Uri.parse("$url/$id"), headers: _headers)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete meeting (${response.statusCode}): ${response.body}");
    }
  }
}
