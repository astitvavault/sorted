import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo_app/data/database.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  ToDoDatabase db = ToDoDatabase();
  final _MyBox = Hive.box('MyBox');

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
    db.loadData();
    _selectedDay = _focusedDay;
    _loadDayData(_selectedDay!);
  }

  void _loadDayData(DateTime date) {
    setState(() {
      _currentDayData = db.getDataForDate(date);
      // Migration/Safety: ensure lists exist
      _currentDayData["tasks"] ??= [];
      _currentDayData["meetings"] ??= [];
      _currentDayData["reminders"] ??= [];
    });
  }

  void _saveCurrentDayData() {
    if (_selectedDay != null) {
      db.saveDataForDate(_selectedDay!, _currentDayData);
    }
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        // [name, completed, isHighPriority, timerInSeconds, description, taskTime]
        _currentDayData["tasks"].add([
          _taskController.text, 
          false, 
          false, 
          0, 
          "", 
          DateFormat.jm().format(DateTime.now())
        ]);
        _taskController.clear();
      });
      _saveCurrentDayData();
    }
  }

  void _addMeeting() {
    if (_meetingTitleController.text.isNotEmpty) {
      setState(() {
        _currentDayData["meetings"].add({
          "title": _meetingTitleController.text,
          "link": _meetingLinkController.text,
        });
        _meetingTitleController.clear();
        _meetingLinkController.clear();
      });
      _saveCurrentDayData();
    }
  }

  void _addReminder() {
    if (_reminderController.text.isNotEmpty) {
      setState(() {
        _currentDayData["reminders"].add(_reminderController.text);
        _reminderController.clear();
      });
      _saveCurrentDayData();
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

                  // Custom Reminder Section
                  _buildSectionTitle("Reminders"),
                  ...(_currentDayData["reminders"] as List).map((r) => _buildItemTile(r, Icons.notification_important, type: 'reminder')),
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
                      color: Colors.white.withOpacity(0.05),
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
    // Ensure task is a list [name, completed, ..., description, taskTime]
    String name = task is List ? task[0] : task.toString();
    bool isCompleted = task is List && task.length > 1 ? task[1] : false;
    String description = task is List && task.length > 4 ? task[4] : "";
    String taskTime = task is List && task.length > 5 ? task[5] : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (task is List && task.length > 1) {
                      task[1] = !task[1];
                    }
                  });
                  _saveCurrentDayData();
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
                onTap: () {
                  setState(() {
                    _currentDayData["tasks"].remove(task);
                  });
                  _saveCurrentDayData();
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

  Widget _buildItemTile(String text, IconData icon, {required String type}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4B483), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (type == 'reminder') {
                  _currentDayData["reminders"].remove(text);
                }
              });
              _saveCurrentDayData();
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
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
            onTap: () {
              setState(() {
                _currentDayData["meetings"].remove(meeting);
              });
              _saveCurrentDayData();
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
