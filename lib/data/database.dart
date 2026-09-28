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

  // Load from local Hive first, then attempt backend sync
  Future<void> loadData() async {
    // 1. Always load local Hive data immediately for zero latency
    profileData = Map<dynamic, dynamic>.from(_MyBox.get("PROFILEDATA") ?? {});
    toDoList = List.from(_MyBox.get("TODOLIST") ?? []);
    calendarData = Map<dynamic, dynamic>.from(_MyBox.get("CALENDARDATA") ?? {});
    notesList = List.from(_MyBox.get("NOTESLIST") ?? []);

    int? profileId = profileData["id"];
    bool isLocalFallbackId = profileId != null && profileId > 100000000;

    // 2. Try fetching remote profile or self-healing fallback ID
    if (profileId != null && !isLocalFallbackId) {
      try {
        Profile remoteProfile = await _profileService.getProfileById(profileId);
        profileData = Map<dynamic, dynamic>.from(remoteProfile.toJson());
        profileData["isRegistered"] = true;
        await _MyBox.put("PROFILEDATA", profileData);
      } catch (e) {
        print("Could not fetch remote profile $profileId: $e");
        if (e.toString().contains("404")) {
          isLocalFallbackId = true; // Mark to create on backend
        }
      }
    }

    // Auto-register profile on backend if profileId is missing, is a local fallback ID, or returned 404
    if ((profileId == null || isLocalFallbackId) && (profileData["fullName"] != null || profileData["name"] != null)) {
      try {
        String nameStr = profileData["fullName"] ?? profileData["name"] ?? "User";
        Profile newProfile = Profile(
          fullName: nameStr,
          bio: profileData["bio"],
          birthDate: profileData["birthDate"],
        );
        Profile created = await _profileService.createProfile(newProfile);
        final createdId = created.id;
        if (createdId != null) {
          profileId = createdId;
          profileData["id"] = createdId;
          profileData["isRegistered"] = true;
          await _MyBox.put("PROFILEDATA", profileData);
          print("Successfully auto-registered profile on backend with real ID: $profileId");
        }
      } catch (e) {
        print("Profile auto-registration on backend failed: $e");
      }
    }

    if (profileId == null) return;

    try {
      // 3. Fetch Todos for this profile
      try {
        List<Todo> apiTodos = await _todoService.getTodosByProfile(profileId);
        String todayKey = _getDateKey(DateTime.now());
        
        List remoteTodayList = apiTodos
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

        if (remoteTodayList.isNotEmpty) {
          toDoList = remoteTodayList;
        }

        // Merge/update calendar data
        for (var t in apiTodos) {
          if (t.dueDate != null) {
            calendarData[t.dueDate] ??= {"tasks": [], "meetings": [], "reminders": []};
            List tasksForDate = List.from(calendarData[t.dueDate]["tasks"] ?? []);
            
            int existingIndex = tasksForDate.indexWhere((item) => item.length > 6 && item[6] == t.id);
            var taskItem = [
              t.title,
              t.completed,
              false,
              0,
              t.description ?? '',
              "",
              t.id,
            ];

            if (existingIndex >= 0) {
              tasksForDate[existingIndex] = taskItem;
            } else {
              tasksForDate.add(taskItem);
            }
            calendarData[t.dueDate]["tasks"] = tasksForDate;
          }
        }
      } catch (e) {
        print("Error fetching remote todos: $e");
      }

      // 4. Fetch Notes
      try {
        List<Note> apiNotes = await _noteService.getNotesByProfile(profileId);
        if (apiNotes.isNotEmpty) {
          notesList = apiNotes.map((n) => [
            n.title,
            n.content ?? '',
            "",
            n.id,
          ]).toList();
        }
      } catch (e) {
        print("Error fetching remote notes: $e");
      }

      // 5. Fetch Meetings
      try {
        List<Meeting> apiMeetings = await _meetingService.getMeetingsByProfile(profileId);
        for (var m in apiMeetings) {
          if (m.meetingTime != null) {
            String dateKey = m.meetingTime!.substring(0, 10);
            calendarData[dateKey] ??= {"tasks": [], "meetings": [], "reminders": []};
            List meetingsList = List.from(calendarData[dateKey]["meetings"] ?? []);
            int existingIndex = meetingsList.indexWhere((item) => item['id'] == m.id);
            var mItem = {
              "title": m.title,
              "link": m.location ?? '',
              "id": m.id,
              "agenda": m.agenda,
              "meetingTime": m.meetingTime,
              "participants": m.participants,
            };
            if (existingIndex >= 0) {
              meetingsList[existingIndex] = mItem;
            } else {
              meetingsList.add(mItem);
            }
            calendarData[dateKey]["meetings"] = meetingsList;
          }
        }
      } catch (e) {
        print("Error fetching remote meetings: $e");
      }

      // 6. Fetch Reminders
      try {
        List<Reminder> apiReminders = await _reminderService.getRemindersByProfile(profileId);
        for (var r in apiReminders) {
          if (r.reminderTime != null) {
            String dateKey = r.reminderTime!.substring(0, 10);
            calendarData[dateKey] ??= {"tasks": [], "meetings": [], "reminders": []};
            List remindersList = List.from(calendarData[dateKey]["reminders"] ?? []);
            int existingIndex = remindersList.indexWhere((item) => item['id'] == r.id);
            var rItem = {
              "text": r.title,
              "id": r.id,
              "reminderTime": r.reminderTime,
              "triggered": r.triggered,
            };
            if (existingIndex >= 0) {
              remindersList[existingIndex] = rItem;
            } else {
              remindersList.add(rItem);
            }
            calendarData[dateKey]["reminders"] = remindersList;
          }
        }
      } catch (e) {
        print("Error fetching remote reminders: $e");
      }

      await updateData();
    } catch (e) {
      print("Global error in loadData: $e");
    }
  }

  Future<void> updateData() async {
    await _MyBox.put("PROFILEDATA", profileData);
    await _MyBox.put("TODOLIST", toDoList);
    await _MyBox.put("CALENDARDATA", calendarData);
    await _MyBox.put("NOTESLIST", notesList);
  }

  // API Interaction methods with reliable local fallbacks
  Future<void> addTask(List task, {DateTime? date}) async {
    DateTime taskDate = date ?? DateTime.now();
    String dateKey = _getDateKey(taskDate);
    int generatedId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    List fullTask = List.from(task);
    if (fullTask.length <= 6) {
      while (fullTask.length < 6) {
        fullTask.add("");
      }
      fullTask.add(generatedId);
    }

    if (dateKey == _getDateKey(DateTime.now())) {
      toDoList.add(fullTask);
    }
    calendarData[dateKey] ??= {"tasks": [], "meetings": [], "reminders": []};
    calendarData[dateKey]["tasks"].add(fullTask);
    await updateData();

    int? profileId = profileData["id"];
    if (profileId != null && profileId < 100000000) {
      try {
        Todo newTodo = Todo(
          title: fullTask[0],
          description: fullTask.length > 4 ? fullTask[4] : '',
          completed: fullTask[1] ?? false,
          dueDate: dateKey,
          profileId: profileId,
        );
        Todo created = await _todoService.createTodo(newTodo);
        final createdId = created.id;
        if (createdId != null) {
          fullTask[6] = createdId;
          await updateData();
        }
      } catch (e) {
        print("Backend sync failed for addTask (saved locally): $e");
      }
    }
  }

  Future<void> updateTask(List task, {DateTime? date}) async {
    int? taskId = task.length > 6 ? task[6] : null;

    await updateData();

    int? profileId = profileData["id"];
    if (profileId != null && taskId != null && profileId < 100000000 && taskId < 100000000) {
      try {
        Todo updatedTodo = Todo(
          id: taskId,
          title: task[0],
          description: task.length > 4 ? task[4] : '',
          completed: task[1] ?? false,
          dueDate: date != null ? _getDateKey(date) : _getDateKey(DateTime.now()),
          profileId: profileId,
        );
        await _todoService.updateTodo(taskId, updatedTodo);
      } catch (e) {
        print("Backend sync failed for updateTask: $e");
      }
    }
  }

  Future<void> deleteTask(int? id) async {
    toDoList.removeWhere((t) => t.length > 6 && t[6] == id);

    calendarData.forEach((key, val) {
      if (val is Map && val["tasks"] is List) {
        (val["tasks"] as List).removeWhere((t) => t.length > 6 && t[6] == id);
      }
    });

    await updateData();

    if (id != null && id < 100000000) {
      try {
        await _todoService.deleteTodo(id);
      } catch (e) {
        print("Backend sync failed for deleteTask: $e");
      }
    }
  }

  Future<int> addReminder(Reminder reminder, {DateTime? date}) async {
    int generatedId = DateTime.now().millisecondsSinceEpoch % 2147483647;
    int? profileId = profileData["id"];

    String dateKey = reminder.reminderTime != null && reminder.reminderTime!.length >= 10
        ? reminder.reminderTime!.substring(0, 10)
        : _getDateKey(date ?? DateTime.now());

    calendarData[dateKey] ??= {"tasks": [], "meetings": [], "reminders": []};
    
    Map<String, dynamic> localReminder = {
      "text": reminder.title,
      "id": generatedId,
      "reminderTime": reminder.reminderTime,
      "triggered": reminder.triggered,
    };
    calendarData[dateKey]["reminders"].add(localReminder);
    await updateData();

    if (profileId != null && profileId < 100000000) {
      try {
        Reminder created = await _reminderService.createReminder(reminder);
        final createdId = created.id;
        if (createdId != null) {
          localReminder["id"] = createdId;
          generatedId = createdId;
          await updateData();
        }
      } catch (e) {
        print("Backend sync failed for reminder, saved locally: $e");
      }
    }

    return generatedId;
  }

  Future<void> deleteReminder(int? id, {DateTime? date}) async {
    if (id == null) return;

    calendarData.forEach((key, val) {
      if (val is Map && val["reminders"] is List) {
        (val["reminders"] as List).removeWhere((r) => r["id"] == id);
      }
    });
    await updateData();

    if (id < 100000000) {
      try {
        await _reminderService.deleteReminder(id);
      } catch (e) {
        print("Failed to delete reminder from API: $e");
      }
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
    String key = _getDateKey(date);
    calendarData[key] = data;
    await updateData();
  }
}
