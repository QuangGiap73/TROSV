class RoomTrust {
  const RoomTrust({
    required this.roomId,
    required this.score,
    required this.riskLevel,
    required this.openReports,
    required this.duplicateImages,
    required this.signals,
    required this.advice,
    this.districtAveragePrice,
  });

  factory RoomTrust.fromJson(Map<String, dynamic> json) => RoomTrust(
    roomId: json['room_id'] as String,
    score: _int(json['score']),
    riskLevel: json['risk_level'] as String? ?? 'UNKNOWN',
    openReports: _int(json['open_reports']),
    duplicateImages: _int(json['duplicate_images']),
    districtAveragePrice: _nullableInt(json['district_average_price']),
    signals: (json['signals'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TrustSignal.fromJson)
        .toList(growable: false),
    advice: (json['advice'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
  );

  final String roomId;
  final int score;
  final String riskLevel;
  final int openReports;
  final int duplicateImages;
  final int? districtAveragePrice;
  final List<TrustSignal> signals;
  final List<String> advice;
}

class TrustSignal {
  const TrustSignal({
    required this.code,
    required this.label,
    required this.impact,
    required this.status,
  });

  factory TrustSignal.fromJson(Map<String, dynamic> json) => TrustSignal(
    code: json['code'] as String? ?? '',
    label: json['label'] as String? ?? '',
    impact: _int(json['impact']),
    status: json['status'] as String? ?? '',
  );

  final String code;
  final String label;
  final int impact;
  final String status;
}

int _int(dynamic value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text) ?? 0,
  _ => 0,
};

int? _nullableInt(dynamic value) => value == null ? null : _int(value);
