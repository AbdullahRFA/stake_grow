import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String communityId;
  final String title;
  final String details;
  final double cost;
  final DateTime date;
  final String type;

  // ✅ NEW: Tracks how much was deducted from each user (UID -> Amount)
  final Map<String, double> expenseShares;

  ActivityModel({
    required this.id,
    required this.communityId,
    required this.title,
    required this.details,
    required this.cost,
    required this.date,
    required this.type,
    required this.expenseShares, // ✅ Required
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
      'expenseShares': expenseShares, // ✅ Saved to DB
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
      // ✅ Load shares safely
      expenseShares: (map['expenseShares'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
      ) ?? {},
    );
  }
}