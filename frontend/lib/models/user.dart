class User {
  final int id;
  final String displayName;

  const User({required this.id, required this.displayName});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as int, displayName: json['display_name'] as String);
}
