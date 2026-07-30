import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class ToDoDatabase {
  List toDoList = []; // This is the list for TODAY
  Map<dynamic, dynamic> calendarData = {};
  List notesList = [];
  Map<dynamic, dynamic> profileData = {};
  final _MyBox = Hive.box('MyBox');

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  void createInitialData() {
    toDoList = [
      ["CODE FOR AN HOUR", false, true, 3600, "Daily coding practice session.", "09:00 AM"],
      ["EXERCISE / WORKOUT", false, false, 0, "Go to the gym for at least 45 mins.", "05:00 PM"]
    ];
    calendarData = {};
    notesList = [
      ["My First Note", "This is a sample note to get you started.", DateFormat.yMMMd().format(DateTime.now())]
    ];
    profileData = {};
    updateData();
  }

  void loadData() {
    toDoList = _MyBox.get("TODOLIST") ?? [];
    calendarData = _MyBox.get("CALENDARDATA") ?? {};
    notesList = _MyBox.get("NOTESLIST") ?? [];
    profileData = _MyBox.get("PROFILEDATA") ?? {};
    
    // Sync Today's tasks from TODOLIST to CALENDARDATA
    String todayKey = _getDateKey(DateTime.now());
    if (!calendarData.containsKey(todayKey)) {
      calendarData[todayKey] = {"tasks": [], "meetings": [], "reminders": []};
    }
    calendarData[todayKey]["tasks"] = toDoList;
  }

  void updateData() {
    // Before saving, ensure Today's tasks in calendarData are updated from toDoList
    String todayKey = _getDateKey(DateTime.now());
    if (!calendarData.containsKey(todayKey)) {
      calendarData[todayKey] = {"tasks": [], "meetings": [], "reminders": []};
    }
    calendarData[todayKey]["tasks"] = toDoList;

    _MyBox.put("TODOLIST", toDoList);
    _MyBox.put("CALENDARDATA", calendarData);
    _MyBox.put("NOTESLIST", notesList);
    _MyBox.put("PROFILEDATA", profileData);
  }

  Map<String, dynamic> getDataForDate(DateTime date) {
    String key = _getDateKey(date);
    
    // If it's today, return the live toDoList
    if (key == _getDateKey(DateTime.now())) {
      Map<String, dynamic> data = calendarData.containsKey(key) 
          ? Map<String, dynamic>.from(calendarData[key])
          : {"tasks": [], "meetings": [], "reminders": []};
      data["tasks"] = toDoList;
      return data;
    }

    if (calendarData.containsKey(key)) {
      var data = Map<String, dynamic>.from(calendarData[key]);
      data["tasks"] ??= [];
      data["meetings"] ??= [];
      data["reminders"] ??= [];
      return data;
    }
    return {"tasks": [], "meetings": [], "reminders": []};
  }

  void saveDataForDate(DateTime date, Map<String, dynamic> data) {
    String key = _getDateKey(date);
    
    // If it's today, update the main toDoList too
    if (key == _getDateKey(DateTime.now())) {
      toDoList = List.from(data["tasks"]);
    }

    calendarData[key] = data;
    updateData();
  }
}
