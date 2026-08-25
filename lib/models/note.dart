class Note {
  final int? id;
  final String title;
  final String? content;
  final int? profileId;

  Note({
    this.id,
    required this.title,
    this.content,
    this.profileId,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'],
      profileId: json['profileId'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "content": content,
        "profileId": profileId,
      };

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? profileId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      profileId: profileId ?? this.profileId,
    );
  }
}
