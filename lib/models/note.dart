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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      "title": title,
    };
    if (id != null) data['id'] = id;
    if (content != null) data['content'] = content;
    if (profileId != null) data['profileId'] = profileId;
    return data;
  }

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
