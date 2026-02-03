class WithdrawalModel {
  final String id;
  final String communityId;
  final String userId;
  final String userName;
  final double amount;
  final String reason;
  final String type; // 'Standard' or 'Early Exit'
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestDate;
  final DateTime? approvedDate;

  WithdrawalModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.reason,
    required this.type,
    required this.status,
    required this.requestDate,
    this.approvedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityId': communityId,
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'reason': reason,
      'type': type,
      'status': status,
      'requestDate': requestDate.millisecondsSinceEpoch,
      'approvedDate': approvedDate?.millisecondsSinceEpoch,
    };
  }

  factory WithdrawalModel.fromMap(Map<String, dynamic> map) {
    return WithdrawalModel(
      id: map['id'] ?? '',
      communityId: map['communityId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      type: map['type'] ?? 'Standard',
      status: map['status'] ?? 'pending',
      requestDate: DateTime.fromMillisecondsSinceEpoch(map['requestDate']),
      approvedDate: map['approvedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvedDate'])
          : null,
    );
  }
}