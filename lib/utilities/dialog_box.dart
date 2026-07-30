import 'package:flutter/material.dart';
import 'my_button.dart';

class DialogBox extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final void Function(bool isHighPriority, String timerText) onSave;
  final VoidCallback onCancel;

  DialogBox({
    super.key,
    required this.titleController,
    required this.descController,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  bool isHighPriority = false;
  TextEditingController timerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Task",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: widget.titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Task Title"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: widget.descController,
                style: const TextStyle(color: Colors.white70),
                maxLines: 3,
                decoration: _inputDecoration("Description"),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("High Priority", style: TextStyle(color: Colors.white70)),
                value: isHighPriority,
                activeColor: const Color(0xFFD4B483),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() => isHighPriority = value);
                },
              ),
              if (isHighPriority) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: timerController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Timer (minutes)"),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => widget.onSave(isHighPriority, timerController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4B483),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("Save Task", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD4B483), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
