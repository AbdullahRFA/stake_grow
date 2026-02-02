class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? profession; // ✅ NEW FIELD
  final DateTime createdAt;
  final List<String> joinedCommunities;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.profession, // ✅
    required this.createdAt,
    required this.joinedCommunities,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'profession': profession, // ✅
      'createdAt': createdAt.millisecondsSinceEpoch,
      'joinedCommunities': joinedCommunities,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      profession: map['profession'], // ✅
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      joinedCommunities: List<String>.from(map['joinedCommunities'] ?? []),
    );
  }
}