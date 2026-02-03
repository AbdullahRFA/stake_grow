class CommunityModel {
  final String id;
  final String name;
  final String adminId;
  final List<String> mods;
  final List<String> members;
  final double totalFund;
  final String inviteCode;
  final DateTime createdAt;
  final Map<String, double> monthlySubscriptions;

  // ✅ NEW: Track when each member joined (UID -> Timestamp)
  final Map<String, int> memberJoinDates;

  CommunityModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.mods,
    required this.members,
    required this.totalFund,
    required this.inviteCode,
    required this.createdAt,
    required this.monthlySubscriptions,
    required this.memberJoinDates, // ✅ Required
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'mods': mods,
      'members': members,
      'totalFund': totalFund,
      'inviteCode': inviteCode,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'monthlySubscriptions': monthlySubscriptions,
      'memberJoinDates': memberJoinDates, // ✅ Save
    };
  }

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      adminId: map['adminId'] ?? '',
      mods: List<String>.from(map['mods'] ?? []),
      members: List<String>.from(map['members'] ?? []),
      totalFund: (map['totalFund'] ?? 0.0).toDouble(),
      inviteCode: map['inviteCode'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      monthlySubscriptions: (map['monthlySubscriptions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
      ) ?? {},
      // ✅ Load
      memberJoinDates: (map['memberJoinDates'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
      ) ?? {},
    );
  }
}