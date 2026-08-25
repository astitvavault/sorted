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

  Map<String, dynamic> toJson() => {
        "id": id,
        "profileImage": profileImage,
        "fullName": fullName,
        "birthDate": birthDate,
        "bio": bio,
      };

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
