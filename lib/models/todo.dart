class Todo {
  final int? id;
  final String title;
  final String? description;
  final bool completed;
  final String? dueDate; // YYYY-MM-DD
  final int? profileId;

  // UI Specific fields - not in DTO but needed for current logic?
  // User previously asked for high priority and timer.
  // I will make them optional and handle them via description or metadata if backend doesn't support them.
  // Or I can keep them as is and assume the backend will ignore extra JSON fields if it's strict, 
  // but usually it's better to match exactly.
  // Given the instruction "matching your DTO fields", I will strictly match them.
  
  Todo({
    this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.dueDate,
    this.profileId,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      completed: json['completed'] ?? false,
      dueDate: json['dueDate'],
      profileId: json['profileId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      "title": title,
      "completed": completed,
    };
    if (id != null) data['id'] = id;
    if (description != null) data['description'] = description;
    if (dueDate != null) data['dueDate'] = dueDate;
    if (profileId != null) data['profileId'] = profileId;
    return data;
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
    String? dueDate,
    int? profileId,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      profileId: profileId ?? this.profileId,
    );
  }
}
