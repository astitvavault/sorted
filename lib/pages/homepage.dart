import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/data/database.dart';
import 'package:todo_app/services/notification_service.dart';
import 'package:todo_app/utilities/dialog_box.dart';
import 'package:todo_app/utilities/to_do_tile.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  ToDoDatabase db = ToDoDatabase();
  String _selectedFilter = "All";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await db.loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void checkBoxChanged(bool? value, int index) async {
    setState(() {
      db.toDoList[index][1] = !(db.toDoList[index][1] as bool);
      if (db.toDoList[index][1] == true) {
        db.toDoList[index][3] = 0; // reset timer when completed
      }
    });
    await db.updateTask(db.toDoList[index]);
  }

  void saveNewTask(bool isHighPriority, String timerText) async {
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task title cannot be empty")),
      );
      return;
    }

    int timerInSeconds = 0;
    int? endTime;

    if (isHighPriority) {
      int minutes = int.tryParse(timerText) ?? 0;
      if (minutes > 0) {
        timerInSeconds = minutes * 60;
        DateTime triggerTime = DateTime.now().add(Duration(seconds: timerInSeconds));
        endTime = triggerTime.millisecondsSinceEpoch;

        // Schedule local notification when high-priority task timer finishes
        int notifId = DateTime.now().millisecondsSinceEpoch % 2147483647;
        await NotificationService().scheduleReminder(
          id: notifId,
          title: "Timer Done: $title",
          body: "Time's up for your high-priority task!",
          scheduledTime: triggerTime,
        );
      }
    }

    String desc = _descController.text.trim();
    String time = DateFormat.jm().format(DateTime.now());

    _titleController.clear();
    _descController.clear();
    Navigator.of(context).pop();

    await db.addTask([
      title,
      false,
      isHighPriority,
      endTime ?? 0,
      desc,
      time,
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  void editTask(int index) {
    _titleController.text = db.toDoList[index][0];
    _descController.text = db.toDoList[index].length > 4 ? db.toDoList[index][4] : "";
    
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          titleController: _titleController,
          descController: _descController,
          onSave: (isHighPriority, timerText) async {
            String title = _titleController.text.trim();
            if (title.isEmpty) return;

            int? endTime;
            if (isHighPriority) {
              int minutes = int.tryParse(timerText) ?? 0;
              if (minutes > 0) {
                DateTime triggerTime = DateTime.now().add(Duration(minutes: minutes));
                endTime = triggerTime.millisecondsSinceEpoch;

                int notifId = DateTime.now().millisecondsSinceEpoch % 2147483647;
                await NotificationService().scheduleReminder(
                  id: notifId,
                  title: "Timer Done: $title",
                  body: "Time's up for your high-priority task!",
                  scheduledTime: triggerTime,
                );
              }
            }

            setState(() {
              db.toDoList[index][0] = title;
              db.toDoList[index][2] = isHighPriority;
              db.toDoList[index][3] = endTime ?? 0;
              db.toDoList[index][4] = _descController.text.trim();
            });
            
            _titleController.clear();
            _descController.clear();
            Navigator.of(context).pop();
            
            await db.updateTask(db.toDoList[index]);
          },
          onCancel: () {
            _titleController.clear();
            _descController.clear();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void createNewTask() {
    _titleController.clear();
    _descController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          titleController: _titleController,
          descController: _descController,
          onSave: (isHighPriority, timerText) {
            saveNewTask(isHighPriority, timerText);
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void deleteTask(int index) async {
    int? id = db.toDoList[index].length > 6 ? db.toDoList[index][6] : null;
    setState(() {
      db.toDoList.removeAt(index);
    });
    if (id != null) {
      await db.deleteTask(id);
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

    List filteredTasks = db.toDoList;
    if (_selectedFilter == "In Progress") {
      filteredTasks = db.toDoList.where((t) => t[1] == false).toList();
    } else if (_selectedFilter == "Completed") {
      filteredTasks = db.toDoList.where((t) => t[1] == true).toList();
    }

    int pendingCount = db.toDoList.where((t) => t[1] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: const Color(0xFFD4B483),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tasks",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                          children: [
                            const TextSpan(text: "You have "),
                            TextSpan(
                              text: "$pendingCount pending",
                              style: const TextStyle(color: Color(0xFFD4B483), fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: " items today."),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  _buildFilterChip("All"),
                  _buildFilterChip("In Progress"),
                  _buildFilterChip("Completed"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Date Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Today, ${DateFormat('MMMM d').format(DateTime.now())}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4B483).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "TODAY",
                          style: TextStyle(
                            color: Color(0xFFD4B483),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tasks List or Empty State
            Expanded(
              child: filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        var taskItem = filteredTasks[index];
                        int originalIndex = db.toDoList.indexOf(taskItem);
                        dynamic taskId = taskItem.length > 6 ? taskItem[6] : originalIndex;

                        return ToDoTile(
                          key: ValueKey(taskId),
                          taskName: taskItem[0],
                          taskCompleted: taskItem[1],
                          isHighPriority: taskItem[2],
                          timerInSeconds: taskItem[3],
                          description: taskItem.length > 4 ? taskItem[4] : "",
                          taskTime: taskItem.length > 5 ? taskItem[5] : "",
                          onChanged: (value) => checkBoxChanged(value, originalIndex),
                          deleteFunction: (context) => deleteTask(originalIndex),
                          editFunction: () => editTask(originalIndex),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.task_alt, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            "No tasks found",
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Tap + to create a new task",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4B483) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
