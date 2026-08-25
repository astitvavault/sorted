import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/data/database.dart';
import 'package:todo_app/pages/main_layout.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ToDoDatabase db = ToDoDatabase();
  final ProfileService _profileService = ProfileService();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  DateTime? _selectedDate;
  File? _image;
  final _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4B483),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name and birth date")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Profile newProfile = Profile(
        fullName: _nameController.text,
        bio: _bioController.text,
        birthDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        profileImage: _image?.path, // Backend might expect a URL, but we'll send local path for now
      );

      // Create on backend
      Profile createdProfile = await _profileService.createProfile(newProfile);

      // Save returned ID and metadata locally
      db.profileData = createdProfile.toJson();
      db.profileData["isRegistered"] = true;
      db.updateData();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Color(0xFFD4B483),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch, size: 40, color: Colors.black),
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome to\nSorted",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Let's set up your profile",
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD4B483), width: 2),
                          image: _image != null
                              ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _image == null
                            ? const Icon(Icons.person, color: Colors.white24, size: 60)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4B483),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Name Input
              _buildLabel("Full Name"),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Enter your name"),
              ),
              const SizedBox(height: 20),
              
              // Birth Date
              _buildLabel("Birth Date"),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Select Date"
                            : DateFormat.yMMMd().format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.white24 : Colors.white,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Color(0xFFD4B483), size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Bio/Relevant Stuff
              _buildLabel("Bio / Relevant Info"),
              TextField(
                controller: _bioController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Tell us something about yourself"),
              ),
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4B483),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "GET STARTED",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFD4B483), fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD4B483)),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
