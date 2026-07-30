import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/data/database.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  ToDoDatabase db = ToDoDatabase();
  
  DateTime _selectedMonth = DateTime.now();
  int totalTasks = 0;
  int completedTasks = 0;
  double percentage = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  void _calculateStats() {
    db.loadData();
    
    int total = 0;
    int completed = 0;

    db.calendarData.forEach((key, value) {
      List<String> parts = key.toString().split('-');
      if (parts.length == 3) {
        int year = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        
        if (year == _selectedMonth.year && month == _selectedMonth.month) {
          List tasks = value["tasks"] ?? [];
          for (var task in tasks) {
            total++;
            if (task is List && task.length > 1 && task[1] == true) {
              completed++;
            }
          }
        }
      }
    });

    setState(() {
      totalTasks = total;
      completedTasks = completed;
      percentage = total > 0 ? (completed / total) : 0.0;
    });
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment);
    });
    _calculateStats();
  }

  @override
  Widget build(BuildContext context) {
    String monthDisplay = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Progress", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Month Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left, color: Color(0xFFD4B483)),
                  ),
                  Text(
                    monthDisplay,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right, color: Color(0xFFD4B483)),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              // Goal Card (Made Bigger)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Target Progress",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Task completion for $monthDisplay",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // Circular Progress (Made Bigger)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 220,
                          width: 220,
                          child: CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 15,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4B483)),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "${(percentage * 100).toInt()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "COMPLETE",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50),
                    
                    const Text(
                      "CONSISTENCY IS KEY",
                      style: TextStyle(
                        color: Color(0xFFD4B483),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Stats (Bigger text)
                    _buildStatRow("Total Tasks Created", totalTasks.toString()),
                    const SizedBox(height: 18),
                    _buildStatRow("Tasks Completed", completedTasks.toString()),
                    const SizedBox(height: 18),
                    _buildStatRow("Remaining", (totalTasks - completedTasks).toString()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
