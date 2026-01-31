class LoanModel {
  final String id;
  final String communityId;
  final String borrowerId;
  final String borrowerName;
  final double amount;
  final String reason;
  final DateTime requestDate;
  final DateTime repaymentDate; // কবে ফেরত দিবে
  final String status; // 'pending', 'approved', 'rejected', 'repaid'

  LoanModel({
    required this.id,
    required this.communityId,
    required this.borrowerId,
    required this.borrowerName,
    required this.amount,
    required this.reason,
    required this.requestDate,
    required this.repaymentDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityId': communityId,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'amount': amount,
      'reason': reason,
      'requestDate': requestDate.millisecondsSinceEpoch,
      'repaymentDate': repaymentDate.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'] ?? '',
      communityId: map['communityId'] ?? '',
      borrowerId: map['borrowerId'] ?? '',
      borrowerName: map['borrowerName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      requestDate: DateTime.fromMillisecondsSinceEpoch(map['requestDate']),
      repaymentDate: DateTime.fromMillisecondsSinceEpoch(map['repaymentDate']),
      status: map['status'] ?? 'pending',
    );
  }
}