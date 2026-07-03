class User {
  final String id;
  final String name;
  final String username;
  final String role; // 'admin', 'helpdesk', 'user'
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.isActive = true,
  });
}
