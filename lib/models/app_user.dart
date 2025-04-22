class AppUser {
  final String email;
  final String avatar;

  AppUser({required this.email, required this.avatar});

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(email: map['email'] ?? '', avatar: map['avatar'] ?? '');
  }
}
