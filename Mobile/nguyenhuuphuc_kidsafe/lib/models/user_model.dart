class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // admin, staff, parent, child
  final String? avatar;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar,
    this.token,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isParent => role == 'parent';
  bool get isChild => role == 'child';

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'staff':
        return 'Chuyên viên cứu hộ';
      case 'child':
        return 'Thiết bị trẻ em';
      case 'parent':
      default:
        return 'Phụ huynh';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'parent',
      avatar: json['avatar'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatar,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
    );
  }
}
