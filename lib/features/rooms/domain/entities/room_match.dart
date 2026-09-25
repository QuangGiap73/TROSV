import 'room_summary.dart';

class RoomMatch {
  const RoomMatch({
    required this.room,
    required this.matchScore,
    required this.estimatedMonthlyCost,
    required this.reasons,
    required this.tradeoffs,
  });

  factory RoomMatch.fromJson(Map<String, dynamic> json) {
    final roomJson = json['room'];

    if (roomJson is! Map<String, dynamic>) {
      throw const FormatException('Thông tin phòng phù hợp không hợp lệ.');
    }

    return RoomMatch(
      room: RoomSummary.fromJson(roomJson),
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      estimatedMonthlyCost:
          (json['estimated_monthly_cost'] as num?)?.toInt() ?? 0,
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      tradeoffs: (json['tradeoffs'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  final RoomSummary room;
  final int matchScore;
  final int estimatedMonthlyCost;
  final List<String> reasons;
  final List<String> tradeoffs;
}
