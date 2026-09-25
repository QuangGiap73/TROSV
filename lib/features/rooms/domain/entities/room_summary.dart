class RoomSummary {
  const RoomSummary({
    required this.id,
    required this.title,
    required this.roomType,
    required this.priceMonthly,
    required this.areaM2,
    required this.addressText,
    required this.district,
    required this.province,
    required this.imageUrl,
    required this.isVerified,
    this.propertyName = '',
    this.ward = '',
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.imageUrls = const [],
    this.relevanceScore,
    this.hasVideo = false,
    this.lastConfirmedAt,
    this.publishedAt,
    this.createdAt,
  });

  factory RoomSummary.fromJson(Map<String, dynamic> json) => RoomSummary(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Phòng chưa có tên',
    roomType: json['room_type'] as String? ?? 'UNKNOWN',
    priceMonthly: (json['price_monthly'] as num?)?.toInt() ?? 0,
    areaM2: (json['area_m2'] as num?)?.toDouble() ?? 0,
    addressText: json['address_text'] as String? ?? '',
    district: json['district'] as String? ?? '',
    province: json['province'] as String? ?? '',
    imageUrl: json['primary_image_url'] as String?,
    isVerified: json['is_verified'] as bool? ?? false,
    propertyName: json['property_name'] as String? ?? '',
    ward: json['ward'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    imageUrls: (json['image_urls'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    relevanceScore: (json['relevance_score'] as num?)?.toDouble(),
    hasVideo: json['has_video'] as bool? ?? false,
    lastConfirmedAt: DateTime.tryParse(
      json['last_confirmed_at'] as String? ?? '',
    ),
    publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  final String id;
  final String title;
  final String roomType;
  final int priceMonthly;
  final double areaM2;
  final String addressText;
  final String district;
  final String province;
  final String? imageUrl;
  final bool isVerified;
  final String propertyName;
  final String ward;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final List<String> imageUrls;
  final double? relevanceScore;
  final bool hasVideo;
  final DateTime? lastConfirmedAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  String get fullAddress => [
    addressText,
    ward,
    district,
    province,
  ].where((value) => value.trim().isNotEmpty).join(', ');
}
