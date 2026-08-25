import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../models/meeting.dart';
import '../models/profile.dart';
import '../services/todo_service.dart';
import '../services/note_service.dart';
import '../services/reminder_service.dart';
import '../services/meeting_service.dart';
import '../services/profile_service.dart';

class ToDoDatabase {
  List toDoList = []; // Local cache for Today's Todos
  Map<dynamic, dynamic> calendarData = {}; // Local cache for all items
  List notesList = []; // Local cache for Notes
  Map<dynamic, dynamic> profileData = {}; // Current active profile metadata
  
  final _MyBox = Hive.box('MyBox');
  
  final TodoService _todoService = TodoService();
  final NoteService _noteService = NoteService();
  final ReminderService _reminderService = ReminderService();
  final MeetingService _meetingService = MeetingService();
  final ProfileService _profileService = ProfileService();

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Load from API based on the active profile ID
  Future<void> loadData() async {
    try {
      // 1. Get active profile info from Hive
      profileData = _MyBox.get("PROFILEDATA") ?? {};
      int? profileId = profileData["id"];

      if (profileId == null) {
        // No profile registered yet, use local Hive if any
        toDoList = _MyBox.get("TODOLIST") ?? [];
        calendarData = _MyBox.get("CALENDARDATA") ?? {};
        notesList = _MyBox.get("NOTESLIST") ?? [];
        return;
      }

      // 2. Fetch Profile from Backend to stay in sync
      Profile remoteProfile = await _profileService.getProfileById(profileId);
      profileData = remoteProfile.toJson();
      profileData["isRegistered"] = true; // Keep local flag
      _MyBox.put("PROFILEDATA", profileData);

      // 3. Fetch Todos for this profile
      List<Todo> apiTodos = await _todoService.getTodosByProfile(profileId);
      
      // Filter for today's tasks to populate toDoList
      String todayKey = _getDateKey(DateTime.now());
      toDoList = apiTodos
          .where((t) => t.dueDate == todayKey)
          .map((t) => [
                t.title,
                t.completed,
                false, // high priority placeholder
                0, // timer placeholder
                t.description ?? '',
                "", // task time placeholder
                t.id,
              ])
          .toList();

      // 4. Load Notes
      List<Note> apiNotes = await _noteService.getNotesByProfile(profileId);
      notesList = apiNotes.map((n) => [
        n.title,
        n.content ?? '',
        "", // date placeholder
        n.id,
      ]).toList();

      // 5. Sync Calendar Data
      calendarData = {};
      
      // Add all todos to calendar
      for (var t in apiTodos) {
        if (t.dueDate != null) {
          calendarData[t.dueDate] ??= {"tasks": [], "meetings": [], "reminders": []};
          calendarData[t.dueDate]["tasks"].add([
            t.title,
            t.completed,
            false,
            0,
            t.description ?? '',
            "",
            t.id,
          ]);
        }
      }

      // Fetch and add meetings
      List<Meeting> apiMeetings = await _meetingService.getMeetingsByProfile(profileId);
      for (var m in apiMeetings) {
        if (m.meetingTime != null) {
          String dateKey = m.meetingTime!.substring(0, 10);
          calendarData[dateKey] ??= {"tasks": [], "meetings": [], "reminders": []};
          calendarData[dateKey]["meetings"].add({
            "title": m.title,
            "link": m.location ?? '',
            "id": m.id,
            "agenda": m.agenda,
            "meetingTime": m.meetingTime,
            "participants": m.participants,
          });
        }
      }

      // Fetch and add reminders
      List<Reminder> apiReminders = await _reminderService.getRemindersByProfile(profileId);
      for (var r in apiReminders) {
        if (r.reminderTime != null) {
          String dateKey = r.reminderTime!.substring(0, 10);
          calendarData[dateKey] ??= {"tasks": [], "meetings": [], "reminders": []};
          calendarData[dateKey]["reminders"].add({
            "text": r.title,
            "id": r.id,
            "reminderTime": r.reminderTime,
            "triggered": r.triggered,
          });
        }
      }

    } catch (e) {
      print("Error loading data from API: $e");
      // Fallback to Hive
      toDoList = _MyBox.get("TODOLIST") ?? [];
      calendarData = _MyBox.get("CALENDARDATA") ?? {};
      notesList = _MyBox.get("NOTESLIST") ?? [];
    }
  }

  Future<void> updateData() async {
    // Mostly keeping Hive as a local cache/backup
    _MyBox.put("PROFILEDATA", profileData);
    _MyBox.put("TODOLIST", toDoList);
    _MyBox.put("CALENDARDATA", calendarData);
    _MyBox.put("NOTESLIST", notesList);
  }

  // API Interaction methods
  Future<void> addTask(List task, {DateTime? date}) async {
    int? profileId = profileData["id"];
    if (profileId == null) return;

    DateTime taskDate = date ?? DateTime.now();
    Todo newTodo = Todo(
      title: task[0],
      description: task.length > 4 ? task[4] : '',
      completed: task[1],
      dueDate: _getDateKey(taskDate),
      profileId: profileId,
    );

    try {
      Todo created = await _todoService.createTodo(newTodo);
      await loadData(); // Full refresh to ensure consistency
    } catch (e) {
      print("Failed to add task: $e");
    }
  }

  Future<void> updateTask(List task, {DateTime? date}) async {
    int? profileId = profileData["id"];
    int? taskId = task.length > 6 ? task[6] : null;
    if (profileId == null || taskId == null) return;

    Todo updatedTodo = Todo(
      id: taskId,
      title: task[0],
      description: task.length > 4 ? task[4] : '',
      completed: task[1],
      dueDate: date != null ? _getDateKey(date) : _getDateKey(DateTime.now()),
      profileId: profileId,
    );

    try {
      await _todoService.updateTodo(taskId, updatedTodo);
      await loadData();
    } catch (e) {
      print("Failed to update task: $e");
    }
  }

  Future<void> deleteTask(int? id) async {
    if (id == null) return;
    try {
      await _todoService.deleteTodo(id);
      await loadData();
    } catch (e) {
      print("Failed to delete task: $e");
    }
  }

  Map<String, dynamic> getDataForDate(DateTime date) {
    String key = _getDateKey(date);
    if (calendarData.containsKey(key)) {
      var data = Map<String, dynamic>.from(calendarData[key]);
      data["tasks"] ??= [];
      data["meetings"] ??= [];
      data["reminders"] ??= [];
      return data;
    }
    return {"tasks": [], "meetings": [], "reminders": []};
  }

  Future<void> saveDataForDate(DateTime date, Map<String, dynamic> data) async {
    // Usually handled by granular add/update methods now.
    String key = _getDateKey(date);
    calendarData[key] = data;
    updateData();
  }
}
