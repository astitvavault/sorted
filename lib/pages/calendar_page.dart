import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo_app/data/database.dart';
import 'package:todo_app/models/meeting.dart';
import 'package:todo_app/models/reminder.dart';
import 'package:todo_app/services/meeting_service.dart';
import 'package:todo_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  ToDoDatabase db = ToDoDatabase();
  final MeetingService _meetingService = MeetingService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  // Controllers for inputs
  final _taskController = TextEditingController();
  final _meetingTitleController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _reminderController = TextEditingController();

  Map<String, dynamic> _currentDayData = {
    "tasks": [],
    "meetings": [],
    "reminders": [],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _refreshData();
  }

  Future<void> _refreshData() async {
    await db.loadData();
    if (mounted) {
      _loadDayData(_selectedDay!);
    }
  }

  void _loadDayData(DateTime date) {
    setState(() {
      _currentDayData = db.getDataForDate(date);
      _currentDayData["tasks"] ??= [];
      _currentDayData["meetings"] ??= [];
      _currentDayData["reminders"] ??= [];
      _isLoading = false;
    });
  }

  void _addTask() async {
    if (_taskController.text.trim().isNotEmpty) {
      String title = _taskController.text.trim();
      _taskController.clear();
      await db.addTask([
        title, 
        false, 
        false, 
        0, 
        "", 
        DateFormat.jm().format(DateTime.now())
      ], date: _selectedDay);
      _loadDayData(_selectedDay!);
    }
  }

  void _addMeeting() async {
    if (_meetingTitleController.text.trim().isNotEmpty) {
      String title = _meetingTitleController.text.trim();
      String link = _meetingLinkController.text.trim();
      _meetingTitleController.clear();
      _meetingLinkController.clear();

      final targetDate = _selectedDay ?? _focusedDay;
      String dateIso = DateFormat('yyyy-MM-ddTHH:mm:ss').format(targetDate);
      String dateKey = DateFormat('yyyy-MM-dd').format(targetDate);
      int localId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      var newMeetingMap = {
        "title": title,
        "link": link,
        "id": localId,
        "meetingTime": dateIso,
      };

      setState(() {
        db.calendarData[dateKey] ??= {"tasks": [], "meetings": [], "reminders": []};
        (db.calendarData[dateKey]["meetings"] as List).add(newMeetingMap);
      });
      await db.updateData();

      int? profileId = db.profileData["id"];
      if (profileId != null) {
        try {
          Meeting newMeeting = Meeting(
            title: title, 
            location: link, 
            meetingTime: dateIso,
            profileId: profileId,
          );
          Meeting created = await _meetingService.createMeeting(newMeeting);
          final createdId = created.id;
          if (createdId != null) {
            newMeetingMap["id"] = createdId;
            await db.updateData();
          }
        } catch (e) {
          print("Backend meeting sync failed (saved locally): $e");
        }
      }

      _loadDayData(targetDate);
    }
  }

  void _addReminder() async {
    int profileId = db.profileData["id"] ?? 1;

    if (_reminderController.text.trim().isNotEmpty) {
      String text = _reminderController.text.trim();
      
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime == null) return;

      final targetDate = _selectedDay ?? _focusedDay;
      DateTime scheduledDateTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (scheduledDateTime.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot schedule a reminder in the past. Please choose a future time."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      String dateIso = scheduledDateTime.toIso8601String();
      _reminderController.clear();

      Reminder newReminder = Reminder(
        title: text, 
        reminderTime: dateIso,
        profileId: profileId,
      );
      
      try {
        int reminderId = await db.addReminder(newReminder, date: targetDate);
        
        // Schedule local notification
        await NotificationService().scheduleReminder(
          id: reminderId,
          title: 'Reminder: Sorted',
          body: text,
          scheduledTime: scheduledDateTime,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Reminder set for ${DateFormat.jm().format(scheduledDateTime)}"),
              backgroundColor: const Color(0xFFD4B483),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to set reminder: $e")),
          );
        }
      }
      
      _refreshData();
    }
  }

  bool _hasEvents(DateTime day) {
    var data = db.getDataForDate(day);
    return (data["tasks"]?.isNotEmpty ?? false) ||
        (data["meetings"]?.isNotEmpty ?? false) ||
        (data["reminders"]?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4B483))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Calendar",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadDayData(selectedDay);
                },
                eventLoader: (day) {
                  return _hasEvents(day) ? [true] : [];
                },
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Color(0xFFD4B483),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(0x66D4B483),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFD4B483),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: Colors.black),
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  outsideTextStyle: TextStyle(color: Colors.white24),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white60),
                  weekendStyle: TextStyle(color: Colors.white38),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Day Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(_selectedDay!),
                    style: const TextStyle(color: Color(0xFFD4B483), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  // Reminders Section
                  _buildSectionTitle("Reminders"),
                  ...(_currentDayData["reminders"] as List).map((r) {
                    String timeStr = "";
                    if (r['reminderTime'] != null) {
                      DateTime dt = DateTime.parse(r['reminderTime']);
                      timeStr = DateFormat.jm().format(dt);
                    }
                    return _buildItemTile(
                      r['text'] ?? r['title'] ?? '', 
                      Icons.notification_important, 
                      id: r['id'], 
                      type: 'reminder',
                      subtitle: timeStr,
                    );
                  }),
                  _buildInputRow(_reminderController, "Set a reminder...", _addReminder),
                  
                  const Divider(color: Colors.white10, height: 40),

                  // Tasks Section
                  _buildSectionTitle("Tasks"),
                  ...(_currentDayData["tasks"] as List).map((task) => _buildTaskTile(task)),
                  _buildInputRow(_taskController, "Add task...", _addTask),

                  const SizedBox(height: 20),

                  // Meetings Section
                  _buildSectionTitle("Meetings"),
                  ...(_currentDayData["meetings"] as List).map((m) => _buildMeetingTile(m)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _meetingTitleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Meeting Title",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                        TextField(
                          controller: _meetingLinkController,
                          style: const TextStyle(color: Colors.white70),
                          decoration: const InputDecoration(
                            hintText: "Meeting Link",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _addMeeting,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4B483),
                              foregroundColor: Colors.black,
                              minimumSize: const Size(80, 36),
                            ),
                            child: const Text("Add Meeting"),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTaskTile(dynamic task) {
    String name = task is List ? task[0] : task.toString();
    bool isCompleted = task is List && task.length > 1 ? task[1] : false;
    String description = task is List && task.length > 4 ? task[4] : "";
    String taskTime = task is List && task.length > 5 ? task[5] : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  setState(() {
                    if (task is List && task.length > 1) {
                      task[1] = !task[1];
                    }
                  });
                  await db.updateTask(task, date: _selectedDay);
                },
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: const Color(0xFFD4B483),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white70,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  int? id = task.length > 6 ? task[6] : null;
                  await db.deleteTask(id);
                  _refreshData();
                },
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30.0, top: 4),
              child: Text(description, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          if (taskTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30.0, top: 4),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white38, size: 12),
                  const SizedBox(width: 4),
                  Text(taskTime, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemTile(String text, IconData icon, {int? id, required String type, String subtitle = ""}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4B483), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(color: Colors.white70)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (id != null) {
                if (type == 'reminder') {
                  await db.deleteReminder(id);
                  await NotificationService().cancelReminder(id);
                }
                _refreshData();
              }
            },
            child: const Icon(Icons.close, color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingTile(dynamic meeting) {
    String title = meeting['title'] ?? "";
    String link = meeting['link'] ?? "";
    int? id = meeting['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: Color(0xFFD4B483), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                if (link.isNotEmpty)
                  Text(link, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, decoration: TextDecoration.underline)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (id != null) {
                try {
                  await _meetingService.deleteMeeting(id);
                } catch (e) {
                  print("Failed to delete meeting from backend: $e");
                }
                _refreshData();
              }
            },
            child: const Icon(Icons.close, color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(TextEditingController controller, String hint, VoidCallback onAdd) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle, color: Color(0xFFD4B483)),
        ),
      ],
    );
  }
}
