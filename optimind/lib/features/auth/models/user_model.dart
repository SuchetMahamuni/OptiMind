class UserModel {
  final int id;
  final String username;
  final String email;
  final int focusScore;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.focusScore,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['name'] ?? '',
      email: json['email'] ?? '',
      focusScore: json['focus_score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': username,
      'email': email,
      'focus_score': focusScore,
    };
  }
}
