import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/data/database.dart';
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
      db.toDoList[index][1] = !db.toDoList[index][1];
      if (db.toDoList[index][1] == true) {
        db.toDoList[index][3] = 0;
      }
    });
    // Call API to update
    await db.updateTask(db.toDoList[index]);
  }

  void saveNewTask(bool isHighPriority, String timerText) async {
    int timerInSeconds = 0;
    int? endTime;

    if (isHighPriority) {
      int minutes = int.tryParse(timerText) ?? 0;
      timerInSeconds = minutes * 60;
      endTime = DateTime.now().millisecondsSinceEpoch + (timerInSeconds * 1000);
    }

    String title = _titleController.text;
    String desc = _descController.text;
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
    
    _loadInitialData(); // Refresh list
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
            int? endTime;

            if (isHighPriority) {
              int minutes = int.tryParse(timerText) ?? 0;
              int timerInSeconds = minutes * 60;
              endTime = DateTime.now().millisecondsSinceEpoch + (timerInSeconds * 1000);
            }

            setState(() {
              db.toDoList[index][0] = _titleController.text;
              db.toDoList[index][2] = isHighPriority;
              db.toDoList[index][3] = endTime ?? 0;
              db.toDoList[index][4] = _descController.text;
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
        }
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
                          color: const Color(0xFFD4B483).withOpacity(0.2),
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
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: const [
                        Text("View Schedule", style: TextStyle(color: Colors.white38, fontSize: 12)),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white38),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tasks List
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  int originalIndex = db.toDoList.indexOf(filteredTasks[index]);
                  return ToDoTile(
                    taskName: filteredTasks[index][0],
                    taskCompleted: filteredTasks[index][1],
                    isHighPriority: filteredTasks[index][2],
                    timerInSeconds: filteredTasks[index][3],
                    description: filteredTasks[index].length > 4 ? filteredTasks[index][4] : "",
                    taskTime: filteredTasks[index].length > 5 ? filteredTasks[index][5] : "",
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
