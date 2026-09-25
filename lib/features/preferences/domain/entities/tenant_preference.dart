class TenantPreference {
  const TenantPreference({
    this.id,
    this.userId,
    this.university,
    this.district,
    this.latitude,
    this.longitude,
    this.radiusKm = 5,
    required this.budgetMax,
    this.roomType,
    this.maxPeople = 1,
    this.amenities = const [],
    this.bathroomPrivate = false,
    this.hasBalcony = false,
    this.alertsEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TenantPreference.fromJson(Map<String, dynamic> json) {
    return TenantPreference(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      university: json['university'] as String?,
      district: json['district'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 5,
      budgetMax: (json['budget_max'] as num?)?.toInt() ?? 0,
      roomType: json['room_type'] as String?,
      maxPeople: ((json['max_people'] as num?)?.toInt() ?? 1).clamp(1, 4),
      amenities: (json['amenities'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      bathroomPrivate: json['bathroom_private'] as bool? ?? false,
      hasBalcony: json['has_balcony'] as bool? ?? false,
      alertsEnabled: json['alerts_enabled'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  final String? id;
  final String? userId;
  final String? university;
  final String? district;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final int budgetMax;
  final String? roomType;
  final int maxPeople;
  final List<String> amenities;
  final bool bathroomPrivate;
  final bool hasBalcony;
  final bool alertsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toRequestJson() {
    return {
      'university': _nullableText(university),
      'district': _nullableText(district),
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'budget_max': budgetMax,
      'room_type': roomType,
      'max_people': maxPeople.clamp(1, 4),
      'amenities': amenities,
      'bathroom_private': bathroomPrivate,
      'has_balcony': hasBalcony,
      'alerts_enabled': alertsEnabled,
    };
  }
  Map<String, dynamic> toMatchRequestJson({int limit = 10}) {
  return {
    'university': _nullableText(university),
    'district': _nullableText(district),
    'latitude': latitude,
    'longitude': longitude,
    'radius_km': radiusKm,
    'budget_max': budgetMax,
    'room_type': roomType,
    'max_people': maxPeople.clamp(1, 4),
    'amenities': amenities,
    'bathroom_private': bathroomPrivate,
    'has_balcony': hasBalcony,
    'limit': limit.clamp(1, 30),
  };
}

  static String? _nullableText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
