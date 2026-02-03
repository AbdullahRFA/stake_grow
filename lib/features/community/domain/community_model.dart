class CommunityModel {
  final String id;
  final String name;
  final String adminId; // Main Admin (Owner)
  final List<String> mods; // ✅ NEW: Co-Admins (Can do everything except delete/edit)
  final List<String> members; // All members
  final double totalFund;
  final String inviteCode;
  final DateTime createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.mods, // ✅ Required
    required this.members,
    required this.totalFund,
    required this.inviteCode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'mods': mods, // ✅ Save to DB
      'members': members,
      'totalFund': totalFund,
      'inviteCode': inviteCode,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      adminId: map['adminId'] ?? '',
      mods: List<String>.from(map['mods'] ?? []), // ✅ Load from DB
      members: List<String>.from(map['members'] ?? []),
      totalFund: (map['totalFund'] ?? 0.0).toDouble(),
      inviteCode: map['inviteCode'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}