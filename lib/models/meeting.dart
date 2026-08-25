class Meeting {
  final int? id;
  final String title;
  final String? agenda;
  final String? meetingTime; // ISO-8601
  final String? participants;
  final String? location;
  final int? profileId;

  Meeting({
    this.id,
    required this.title,
    this.agenda,
    this.meetingTime,
    this.participants,
    this.location,
    this.profileId,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      title: json['title'] ?? '',
      agenda: json['agenda'],
      meetingTime: json['meetingTime'],
      participants: json['participants'],
      location: json['location'],
      profileId: json['profileId'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "agenda": agenda,
        "meetingTime": meetingTime,
        "participants": participants,
        "location": location,
        "profileId": profileId,
      };

  Meeting copyWith({
    int? id,
    String? title,
    String? agenda,
    String? meetingTime,
    String? participants,
    String? location,
    int? profileId,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      agenda: agenda ?? this.agenda,
      meetingTime: meetingTime ?? this.meetingTime,
      participants: participants ?? this.participants,
      location: location ?? this.location,
      profileId: profileId ?? this.profileId,
    );
  }
}
