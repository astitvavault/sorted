import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/data/database.dart';
import 'package:todo_app/pages/profile_manager_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ToDoDatabase db = ToDoDatabase();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    await db.loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4B483))),
      );
    }

    final profile = db.profileData;
    final String name = (profile["fullName"] as String?) ?? (profile["name"] as String?) ?? "Anonymous";
    final String bio = (profile["bio"] as String?) ?? "No bio added.";
    final String imagePath = (profile["imagePath"] as String?) ?? (profile["profileImage"] as String?) ?? "";
    final DateTime? birthDate = profile["birthDate"] != null ? DateTime.tryParse(profile["birthDate"].toString()) : null;
    
    int? age;
    if (birthDate != null) {
      age = _calculateAge(birthDate);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileManagerPage())).then((_) => _loadProfileData()),
            icon: const Icon(Icons.group_outlined, color: Color(0xFFD4B483)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Column(
          children: [
            // Profile Image
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4B483), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4B483).withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                  image: imagePath.isNotEmpty && File(imagePath).existsSync()
                      ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover)
                      : null,
                ),
                child: (imagePath.isEmpty || !File(imagePath).existsSync())
                    ? const Icon(Icons.person, color: Colors.white24, size: 80)
                    : null,
              ),
            ),
            const SizedBox(height: 25),
            
            // Name
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (age != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "$age years old",
                  style: const TextStyle(color: Color(0xFFD4B483), fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            
            const SizedBox(height: 40),
            
            // Info Cards
            _buildInfoCard("Bio", bio, Icons.info_outline),
            const SizedBox(height: 20),
            _buildInfoCard(
              "Birth Date", 
              birthDate != null ? DateFormat.yMMMMd().format(birthDate) : "Not set", 
              Icons.cake_outlined
            ),
            
            const SizedBox(height: 40),
            
            // Info Note
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock_outline, color: Colors.white24, size: 20),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Profile information is locked and saved locally and synced with your backend.",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD4B483), size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}
