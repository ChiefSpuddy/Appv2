class UserAvatar {
  final String id;
  final String path;

  const UserAvatar({
    required this.id,
    required this.path,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'path': path,
  };

  factory UserAvatar.fromMap(Map<String, dynamic> map) => UserAvatar(
    id: map['id'] as String,
    path: map['path'] as String,
  );
}
