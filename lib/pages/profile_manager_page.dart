import 'dart:io';
import 'package:flutter/material.dart';
import 'package:todo_app/data/database.dart';
import 'package:todo_app/models/profile.dart';
import 'package:todo_app/services/profile_service.dart';
import 'login_page.dart';

class ProfileManagerPage extends StatefulWidget {
  const ProfileManagerPage({super.key});

  @override
  State<ProfileManagerPage> createState() => _ProfileManagerPageState();
}

class _ProfileManagerPageState extends State<ProfileManagerPage> {
  final ProfileService _profileService = ProfileService();
  final ToDoDatabase db = ToDoDatabase();
  List<Profile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    try {
      List<Profile> profiles = await _profileService.getProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profiles: $e")),
      );
    }
  }

  void _switchProfile(Profile profile) async {
    setState(() => _isLoading = true);
    db.profileData = profile.toJson();
    db.profileData["isRegistered"] = true;
    await db.updateData();
    await db.loadData();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Manage Profiles", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
            icon: const Icon(Icons.add, color: Color(0xFFD4B483)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4B483)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                Profile p = _profiles[index];
                bool isActive = p.id == db.profileData["id"];
                return GestureDetector(
                  onTap: () => _switchProfile(p),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? const Color(0xFFD4B483) : Colors.white10,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: p.profileImage != null && File(p.profileImage!).existsSync()
                              ? FileImage(File(p.profileImage!))
                              : null,
                          child: p.profileImage == null
                              ? const Icon(Icons.person, color: Colors.white24)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.fullName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                p.bio ?? "No bio",
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          const Icon(Icons.check_circle, color: Color(0xFFD4B483)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
