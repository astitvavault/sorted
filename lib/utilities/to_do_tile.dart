import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class ToDoTile extends StatefulWidget {
  final String taskName;
  final bool taskCompleted;
  final bool isHighPriority;
  final String description;
  final String taskTime;
  final ValueChanged<bool?>? onChanged;
  final void Function(BuildContext)? deleteFunction;
  final VoidCallback? editFunction;
  final int timerInSeconds;

  const ToDoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.isHighPriority,
    this.description = "",
    this.taskTime = "",
    required this.timerInSeconds,
    required this.onChanged,
    required this.deleteFunction,
    this.editFunction,
  });

  @override
  State<ToDoTile> createState() => _ToDoTileState();
}

class _ToDoTileState extends State<ToDoTile> {
  int _remainingTime = 0;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  void _calculateRemainingTime() {
    _remainingTime = 0;
    if (widget.isHighPriority && widget.timerInSeconds > 0) {
      int now = DateTime.now().millisecondsSinceEpoch;
      if (widget.timerInSeconds > 1000000000) {
        _remainingTime = ((widget.timerInSeconds - now) / 1000).floor();
      } else {
        _remainingTime = widget.timerInSeconds;
      }

      if (_remainingTime > 0 && !widget.taskCompleted) {
        _startTimer();
      } else {
        _remainingTime = 0;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
  }

  @override
  void didUpdateWidget(covariant ToDoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.taskCompleted) {
      _timer?.cancel();
      _remainingTime = 0;
    } else if (oldWidget.timerInSeconds != widget.timerInSeconds ||
        oldWidget.isHighPriority != widget.isHighPriority) {
      _calculateRemainingTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.28,
          children: [
            CustomSlidableAction(
              onPressed: (context) {
                if (widget.deleteFunction != null) {
                  widget.deleteFunction!(context);
                }
              },
              backgroundColor: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(left: 15),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
                ),
              ),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Checkbox
                  GestureDetector(
                    onTap: () => widget.onChanged?.call(!widget.taskCompleted),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: widget.taskCompleted ? const Color(0xFFD4B483) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.taskCompleted ? const Color(0xFFD4B483) : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: widget.taskCompleted
                          ? const Icon(Icons.check, color: Colors.black, size: 18)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.taskName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: widget.taskCompleted ? TextDecoration.lineThrough : null,
                                  decorationColor: Colors.white38,
                                ),
                              ),
                            ),
                            if (widget.editFunction != null)
                              GestureDetector(
                                onTap: widget.editFunction,
                                child: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description.isNotEmpty
                              ? widget.description
                              : "No description provided.",
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              widget.taskTime.isNotEmpty ? widget.taskTime : DateFormat.jm().format(DateTime.now()),
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            const SizedBox(width: 15),
                            // Priority Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.isHighPriority 
                                    ? const Color(0xFFD4B483).withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.isHighPriority ? "HIGH" : "LOW",
                                style: TextStyle(
                                  color: widget.isHighPriority ? const Color(0xFFD4B483) : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!widget.taskCompleted && widget.isHighPriority && _remainingTime > 0) ...[
                              const SizedBox(width: 15),
                              Text(
                                "⏱ ${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD4B483),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
