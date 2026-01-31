class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final List<String> joinedCommunities; // কোন কোন কমিউনিটিতে আছে

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.createdAt,
    required this.joinedCommunities,
  });

  // JSON থেকে ডাটায় কনভার্ট করা (Firebase এর জন্য)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      joinedCommunities: List<String>.from(map['joinedCommunities'] ?? []),
    );
  }
}