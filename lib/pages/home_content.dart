import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/data/database.dart';
import 'package:todo_app/pages/homepage.dart';
import 'package:todo_app/pages/goals_page.dart';
import 'package:todo_app/pages/notes_page.dart';
import 'package:todo_app/pages/main_layout.dart';
import 'package:todo_app/pages/profile_page.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  ToDoDatabase db = ToDoDatabase();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await db.loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4B483))),
      );
    }
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());
    
    final List<String> gogginsQuotes = [
      "Stay hard!",
      "Don't stop when you're tired. Stop when you're done.",
      "The most important conversation is the one you have with yourself.",
      "Comfort zone is where dreams go to die.",
      "Pain is the ticket to a new version of yourself.",
      "Uncommon amongst uncommon.",
      "Master your mind.",
      "Be driven, not motivated.",
      "It’s easy to be great when everyone else is weak.",
      "Roger that.",
      "Mental toughness is a lifestyle.",
    ];

    int dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
    String dailyQuote = gogginsQuotes[dayOfYear % gogginsQuotes.length];

    List recentTasks = db.toDoList.take(3).map((e) => e[0].toString()).toList();
    String latestNote = db.notesList.isNotEmpty ? db.notesList[0][0] : "No notes yet";
    String latestNoteContent = db.notesList.isNotEmpty ? db.notesList[0][1] : "Tap 'Notes' to add one.";
    
    var todayData = db.getDataForDate(DateTime.now());
    List meetings = todayData["meetings"] ?? [];
    String nextMeeting = meetings.isNotEmpty ? meetings[0]['title'] : "No meetings today";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4B483),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch, color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Sorted",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Find the MainLayout state and change index to 4 (Profile)
                          final mainLayoutState = context.findAncestorStateOfType<State<MainLayout>>();
                          if (mainLayoutState != null) {
                            // This depends on how MainLayout is structured, 
                            // but usually we can use a callback or index provider.
                            // For now, let's use a standard navigation push for immediate result
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                          }
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          backgroundImage: db.profileData["imagePath"] != null && db.profileData["imagePath"].isNotEmpty && File(db.profileData["imagePath"]).existsSync()
                              ? FileImage(File(db.profileData["imagePath"]))
                              : null,
                          child: db.profileData["imagePath"] == null || db.profileData["imagePath"].isEmpty || !File(db.profileData["imagePath"]).existsSync()
                              ? const Icon(Icons.person, size: 20, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                dailyQuote.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              // Categories Section
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryItem(Icons.auto_awesome, "Highlights", isSelected: true),
                    _buildCategoryItem(
                      Icons.check_box_outlined, 
                      "To-do",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Homepage())).then((_) => _refreshData()),
                    ),
                    _buildCategoryItem(
                      Icons.trending_up, 
                      "Progress",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GoalsPage())),
                    ),
                    _buildCategoryItem(
                      Icons.edit_note, 
                      "Notes",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotesPage())).then((_) => _refreshData()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHighlightCard(
                      "Tasks Today",
                      recentTasks.isEmpty ? ["No tasks for today"] : recentTasks.cast<String>(),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSmallHighlightCard(
                          "Recent Note", 
                          latestNote,
                          content: latestNoteContent
                        ),
                        const SizedBox(height: 15),
                        _buildSmallHighlightCard(
                          "Next Meeting", 
                          nextMeeting,
                          isMeeting: true
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                "Mindset",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.format_quote, color: Color(0xFFD4B483), size: 35),
                    const SizedBox(height: 15),
                    Text(
                      gogginsQuotes[(dayOfYear + 1) % gogginsQuotes.length],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "— David Goggins",
                      style: TextStyle(
                        color: Color(0xFFD4B483),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4B483) : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.05)),
              ),
              child: Icon(
                icon, 
                color: isSelected ? Colors.black : Colors.white70,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFD4B483) : Colors.white38,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFFD4B483)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item, 
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSmallHighlightCard(String title, String subtitle, {String content = "", bool isMeeting = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMeeting ? Icons.videocam_outlined : Icons.description_outlined, 
                color: const Color(0xFFD4B483), 
                size: 16
              ),
              const SizedBox(width: 8),
              Text(
                title, 
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              content, 
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      ),
    );
  }
}
