class DonationModel {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final double amount;
  final String type; // 'Monthly' or 'Random'
  final DateTime timestamp;

  DonationModel({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.amount,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityId': communityId,
      'senderId': senderId,
      'senderName': senderName,
      'amount': amount,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      id: map['id'] ?? '',
      communityId: map['communityId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'Random',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}