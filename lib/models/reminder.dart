class Reminder {
  final int? id;
  final String title;
  final String? reminderTime; // ISO-8601
  final bool triggered;
  final int? profileId;

  Reminder({
    this.id,
    required this.title,
    this.reminderTime,
    this.triggered = false,
    this.profileId,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'] ?? '',
      reminderTime: json['reminderTime'],
      triggered: json['triggered'] ?? false,
      profileId: json['profileId'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "reminderTime": reminderTime,
        "triggered": triggered,
        "profileId": profileId,
      };

  Reminder copyWith({
    int? id,
    String? title,
    String? reminderTime,
    bool? triggered,
    int? profileId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      reminderTime: reminderTime ?? this.reminderTime,
      triggered: triggered ?? this.triggered,
      profileId: profileId ?? this.profileId,
    );
  }
}
