import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/profile.dart';

class ProfileService {
  final String url = "${ApiConfig.baseUrl}/profiles";

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<List<Profile>> getProfiles() async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Profile.fromJson(json)).toList();
    }
    throw Exception("Failed to load profiles (${response.statusCode}): ${response.body}");
  }

  Future<Profile> getProfileById(int id) async {
    final response = await http
        .get(Uri.parse("$url/$id"), headers: _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to load profile $id (${response.statusCode}): ${response.body}");
  }

  Future<Profile> createProfile(Profile profile) async {
    debugPrint("ProfileService: POST $url with body: ${jsonEncode(profile.toJson())}");
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(profile.toJson()),
        )
        .timeout(const Duration(seconds: 30));
    
    debugPrint("ProfileService: POST response status ${response.statusCode}, body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Profile.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create profile (${response.statusCode}): ${response.body}");
  }

  Future<Profile> updateProfile(int id, Profile profile) async {
    final response = await http
        .put(
          Uri.parse("$url/$id"),
          headers: _headers,
          body: jsonEncode(profile.toJson()),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Profile.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to update profile (${response.statusCode}): ${response.body}");
  }

  Future<void> deleteProfile(int id) async {
    final response = await http
        .delete(Uri.parse("$url/$id"), headers: _headers)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete profile (${response.statusCode}): ${response.body}");
    }
  }
}
