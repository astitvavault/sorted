import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/adapters.dart';
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
  final _MyBox  = Hive.box('MyBox');
  ToDoDatabase db = ToDoDatabase();
  String _selectedFilter = "All";

  @override
  void initState() {
    if(_MyBox.get("TODOLIST") == null){
      db.createInitialData();
    }
    else{
      db.loadData();
    }
    super.initState();
  }

  void checkBoxChanged(bool? value, int index) {
    setState(() {
      db.toDoList[index][1] = !db.toDoList[index][1];
      if (db.toDoList[index][1] == true) {
        db.toDoList[index][3] = 0;

      }
    });
    db.updateData();
  }

  void saveNewTask(bool isHighPriority, String timerText) {
    int timerInSeconds = 0;
    int? endTime;

    if (isHighPriority) {
      int minutes = int.tryParse(timerText) ?? 0;
      timerInSeconds = minutes * 60;
      endTime = DateTime.now().millisecondsSinceEpoch + (timerInSeconds * 1000);
    }

    setState(() {
      db.toDoList.add([
        _titleController.text,      // task name
        false,                     // completed
        isHighPriority,            // priority
        endTime ?? 0,              // store END TIME
        _descController.text,       // description
        DateFormat.jm().format(DateTime.now()), // task time
      ]);
      _titleController.clear();
      _descController.clear();
    });

    Navigator.of(context).pop();
    db.updateData();
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
          onSave: (isHighPriority, timerText) {
            int timerInSeconds = 0;
            int? endTime;

            if (isHighPriority) {
              int minutes = int.tryParse(timerText) ?? 0;
              timerInSeconds = minutes * 60;
              endTime = DateTime.now().millisecondsSinceEpoch + (timerInSeconds * 1000);
            }

            setState(() {
              db.toDoList[index][0] = _titleController.text;
              db.toDoList[index][2] = isHighPriority;
              db.toDoList[index][3] = endTime ?? 0;
              db.toDoList[index][4] = _descController.text;
              // Keep original creation time? Or update it? User said "real time tag".
              // Usually creation time stays the same.
            });
            
            _titleController.clear();
            _descController.clear();
            Navigator.of(context).pop();
            db.updateData();
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

  void deleteTask(int index) {
    setState(() {
      db.toDoList.removeAt(index);
    });
    db.updateData();
  }
  @override
  Widget build(BuildContext context) {
    List filteredTasks = db.toDoList;
    if (_selectedFilter == "In Progress") {
      filteredTasks = db.toDoList.where((t) => t[1] == false).toList();
    } else if (_selectedFilter == "Completed") {
      filteredTasks = db.toDoList.where((t) => t[1] == true).toList();
    }

    int pendingCount = db.toDoList.where((t) => t[1] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: const Color(0xFFD4B483),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
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
