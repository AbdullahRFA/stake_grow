class CommunityModel {
  final String id;
  final String name;
  final String adminId; // যে কমিউনিটি খুলবে, সে অটোমেটিক এডমিন
  final List<String> members; // মেম্বারদের UID এর লিস্ট
  final double totalFund; // অ্যাপের মেইন ব্যালেন্স
  final String inviteCode; // জয়েন করার গোপন কোড
  final DateTime createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.members,
    required this.totalFund,
    required this.inviteCode,
    required this.createdAt,
  });

  // ডাটাবেসে সেভ করার জন্য Map এ কনভার্ট করা
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'members': members,
      'totalFund': totalFund,
      'inviteCode': inviteCode,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // ডাটাবেস থেকে অ্যাপে আনার জন্য Object এ কনভার্ট করা
  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      adminId: map['adminId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      totalFund: (map['totalFund'] ?? 0.0).toDouble(), // int কে double এ সেফলি কনভার্ট করা
      inviteCode: map['inviteCode'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}