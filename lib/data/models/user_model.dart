class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  // Factory untuk membuat dari JSON (untuk integrasi backend)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
    );
  }
  
  // Konversi ke JSON (untuk integrasi backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }

  // Dummy data untuk testing
  static UserModel currentUser = UserModel(
    id: '1',
    name: 'Sinister',
    email: 'sinister@example.com',
    avatarUrl: null,
  );
}