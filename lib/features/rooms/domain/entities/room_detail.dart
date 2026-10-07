class RoomDetail {
  const RoomDetail({
    required this.id,
    required this.title,
    required this.roomType,
    required this.areaM2,
    required this.maxPeople,
    required this.priceMonthly,
    this.estimatedMonthlyCost,
    required this.depositAmount,
    required this.status,
    required this.address,
    required this.description,
    required this.houseRules,
    required this.imageUrls,
    this.videoUrls = const [],
    required this.amenities,
    this.floor,
    this.cost,
    this.availableDate,
    this.lastConfirmedAt,
    this.publishedAt,
    this.landlordName,
    this.latitude,
    this.longitude,
    this.viewsCount = 0,
  });

  factory RoomDetail.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final images = media
        .where((item) => !_isVideoMedia(item))
        .map((item) => item['public_url'] as String? ?? item['url'] as String?)
        .whereType<String>()
        .toList();
    final videos = media
        .where(_isVideoMedia)
        .map((item) => item['public_url'] as String? ?? item['url'] as String?)
        .whereType<String>()
        .toList(growable: false);
    final fallbackImage = json['image_url'] as String?;
    if (images.isEmpty && fallbackImage != null) images.add(fallbackImage);

    final amenities = (json['amenities'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => item['name'] as String?)
        .whereType<String>()
        .toList();
    final property = json['property'] as Map<String, dynamic>?;
    final costJson = json['cost'] is Map<String, dynamic>
        ? json['cost'] as Map<String, dynamic>
        : null;
    final priceMonthly = _money(json['price_monthly']) ?? 0;
    final estimatedMonthlyCost =
        _money(json['estimated_monthly_cost']) ??
        _money(json['estimated_cost']) ??
        _money(costJson?['estimated_monthly_cost']) ??
        _estimateMonthlyCost(priceMonthly, costJson);
    final address = <String?>[
      json['address_text'] as String?,
      property?['ward'] as String?,
      json['district'] as String?,
      json['province'] as String?,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');

    return RoomDetail(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Phòng chưa có tên',
      roomType: json['room_type'] as String? ?? 'UNKNOWN',
      areaM2: (json['area_m2'] as num?)?.toDouble() ?? 0,
      floor: (json['floor'] as num?)?.toInt(),
      maxPeople: (json['max_people'] as num?)?.toInt() ?? 0,
      priceMonthly: priceMonthly,
      estimatedMonthlyCost: estimatedMonthlyCost,
      depositAmount: (json['deposit_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'UNKNOWN',
      address: address,
      description: json['description'] as String? ?? 'Chưa có mô tả.',
      houseRules: json['house_rules'] as String? ?? 'Chưa có nội quy.',
      imageUrls: images,
      videoUrls: videos,
      amenities: amenities,
      cost: costJson == null ? null : RoomCost.fromJson(costJson),
      availableDate: DateTime.tryParse(json['available_date'] as String? ?? ''),
      lastConfirmedAt: DateTime.tryParse(
        json['last_confirmed_at'] as String? ?? '',
      ),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      landlordName: json['landlord_name'] as String?,
      latitude: (property?['latitude'] as num?)?.toDouble(),
      longitude: (property?['longitude'] as num?)?.toDouble(),
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;
  final String roomType;
  final double areaM2;
  final int? floor;
  final int maxPeople;
  final int priceMonthly;
  final int? estimatedMonthlyCost;
  final int depositAmount;
  final String status;
  final String address;
  final String description;
  final String houseRules;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final List<String> amenities;
  final RoomCost? cost;
  final DateTime? availableDate;
  final DateTime? lastConfirmedAt;
  final DateTime? publishedAt;
  final String? landlordName;
  final double? latitude, longitude;
  final int viewsCount;
}

int? _money(dynamic value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

int? _estimateMonthlyCost(int priceMonthly, Map<String, dynamic>? cost) {
  if (cost == null || priceMonthly <= 0) return null;
  const fixedMonthlyKeys = [
    'internet_fee',
    'parking_fee',
    'service_fee',
    'cleaning_fee',
    'other_fee',
  ];
  return priceMonthly +
      fixedMonthlyKeys.fold<int>(
        0,
        (total, key) => total + (_money(cost[key]) ?? 0),
      );
}

String _mediaType(Map<String, dynamic> media) {
  return (media['media_type'] as String? ?? media['type'] as String? ?? 'IMAGE')
      .toUpperCase();
}

bool _isVideoMedia(Map<String, dynamic> media) {
  if (_mediaType(media) == 'VIDEO') return true;
  final url = media['public_url'] as String? ?? media['url'] as String?;
  return _looksLikeVideoUrl(url);
}

bool _looksLikeVideoUrl(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  final path =
      Uri.tryParse(value.trim())?.path.toLowerCase() ??
      value.trim().toLowerCase();
  return const ['.mp4', '.m4v', '.mov', '.webm', '.3gp'].any(path.endsWith);
}

class RoomCost {
  const RoomCost({
    this.electricityPrice,
    this.waterPrice,
    this.internetFee,
    this.parkingFee,
    this.serviceFee,
    this.cleaningFee,
    this.otherFee,
  });

  factory RoomCost.fromJson(Map<String, dynamic> json) {
    int? money(String key) => (json[key] as num?)?.toInt();
    return RoomCost(
      electricityPrice: money('electricity_price'),
      waterPrice: money('water_price'),
      internetFee: money('internet_fee'),
      parkingFee: money('parking_fee'),
      serviceFee: money('service_fee'),
      cleaningFee: money('cleaning_fee'),
      otherFee: money('other_fee'),
    );
  }

  final int? electricityPrice;
  final int? waterPrice;
  final int? internetFee;
  final int? parkingFee;
  final int? serviceFee;
  final int? cleaningFee;
  final int? otherFee;
}
