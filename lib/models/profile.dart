class Profile {
  final int? id;
  final String? profileImage;
  final String fullName;
  final String? birthDate; // YYYY-MM-DD
  final String? bio;

  Profile({
    this.id,
    this.profileImage,
    required this.fullName,
    this.birthDate,
    this.bio,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      profileImage: json['profileImage'],
      fullName: json['fullName'] ?? '',
      birthDate: json['birthDate'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      "fullName": fullName,
    };
    if (id != null) data['id'] = id;
    if (profileImage != null) data['profileImage'] = profileImage;
    if (birthDate != null) data['birthDate'] = birthDate;
    if (bio != null) data['bio'] = bio;
    return data;
  }

  Profile copyWith({
    int? id,
    String? profileImage,
    String? fullName,
    String? birthDate,
    String? bio,
  }) {
    return Profile(
      id: id ?? this.id,
      profileImage: profileImage ?? this.profileImage,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
    );
  }
}
