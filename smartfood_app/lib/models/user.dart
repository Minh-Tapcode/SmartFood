class User {
  final int id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String role;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  bool get isSeller => role.toLowerCase() == 'seller' || role.toLowerCase() == 'admin';
  bool get isBuyer => role.toLowerCase() == 'buyer';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'],
      role: (json['role'] ?? json['Role'] ?? ((json['isSeller'] ?? false) ? 'seller' : 'buyer')).toString(),
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
      'createdAt': createdAt,
    };
  }
}