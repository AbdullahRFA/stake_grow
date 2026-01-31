class ActivityModel {
  final String id;
  final String communityId;
  final String title; // কাজের নাম (যেমন: Winter Cloth Distribution)
  final String details;
  final double cost; // কত খরচ হবে
  final DateTime date;
  final String type; // 'Social Work', 'Event', 'Maintenance'

  ActivityModel({
    required this.id,
    required this.communityId,
    required this.title,
    required this.details,
    required this.cost,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityId': communityId,
      'title': title,
      'details': details,
      'cost': cost,
      'date': date.millisecondsSinceEpoch,
      'type': type,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      communityId: map['communityId'] ?? '',
      title: map['title'] ?? '',
      details: map['details'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      type: map['type'] ?? 'Social Work',
    );
  }
}