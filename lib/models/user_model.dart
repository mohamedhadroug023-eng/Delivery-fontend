class UserModel {
  final int id;
  final String name;
  final String phone;
  final String role;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['full_name'] ?? json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'phone': phone,
      'role': role,
      'token': token,
    };
  }
}
