import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/profile.dart';

class ProfileService {
  final String url = "${ApiConfig.baseUrl}/profiles";

  Future<List<Profile>> getProfiles() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Profile.fromJson(json)).toList();
    }
    throw Exception("Failed to load profiles");
  }

  Future<Profile> getProfileById(int id) async {
    final response = await http.get(Uri.parse("$url/$id"));
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to load profile $id");
  }

  Future<Profile> createProfile(Profile profile) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(profile.toJson()),
    );
    if (response.statusCode == 201) return Profile.fromJson(jsonDecode(response.body));
    throw Exception("Failed to create profile");
  }

  Future<Profile> updateProfile(int id, Profile profile) async {
    final response = await http.put(
      Uri.parse("$url/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(profile.toJson()),
    );
    if (response.statusCode == 200) return Profile.fromJson(jsonDecode(response.body));
    throw Exception("Failed to update profile");
  }

  Future<void> deleteProfile(int id) async {
    final response = await http.delete(Uri.parse("$url/$id"));
    if (response.statusCode != 204) throw Exception("Failed to delete profile");
  }
}
