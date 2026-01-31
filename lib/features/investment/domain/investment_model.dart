class InvestmentModel {
  final String id;
  final String communityId;
  final String projectName;
  final String details;
  final double investedAmount;
  final double expectedProfit;
  final String status; // 'active', 'completed', 'loss'
  final DateTime startDate;

  InvestmentModel({
    required this.id,
    required this.communityId,
    required this.projectName,
    required this.details,
    required this.investedAmount,
    required this.expectedProfit,
    required this.status,
    required this.startDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityId': communityId,
      'projectName': projectName,
      'details': details,
      'investedAmount': investedAmount,
      'expectedProfit': expectedProfit,
      'status': status,
      'startDate': startDate.millisecondsSinceEpoch,
    };
  }

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] ?? '',
      communityId: map['communityId'] ?? '',
      projectName: map['projectName'] ?? '',
      details: map['details'] ?? '',
      investedAmount: (map['investedAmount'] ?? 0.0).toDouble(),
      expectedProfit: (map['expectedProfit'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'active',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
    );
  }
}