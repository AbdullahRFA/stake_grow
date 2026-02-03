class DonationModel {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final double amount;
  final String type; // 'Monthly' or 'Random'
  final DateTime timestamp;

  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;

  // ✅ NEW FIELDS for Payment Details
  final String paymentMethod; // 'Bkash', 'Rocket', 'Nagad', 'Manual'
  final String? transactionId;
  final String? phoneNumber;

  DonationModel({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.status = 'pending',
    this.rejectionReason,
    this.paymentMethod = 'Manual', // Default
    this.transactionId,
    this.phoneNumber,
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
      'status': status,
      'rejectionReason': rejectionReason,
      'paymentMethod': paymentMethod, // ✅
      'transactionId': transactionId, // ✅
      'phoneNumber': phoneNumber,     // ✅
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
      status: map['status'] ?? 'approved',
      rejectionReason: map['rejectionReason'],
      paymentMethod: map['paymentMethod'] ?? 'Manual', // ✅
      transactionId: map['transactionId'],             // ✅
      phoneNumber: map['phoneNumber'],                 // ✅
    );
  }
}