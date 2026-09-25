class RoomDetail {
  const RoomDetail({
    required this.id,
    required this.title,
    required this.roomType,
    required this.areaM2,
    required this.maxPeople,
    required this.priceMonthly,
    required this.depositAmount,
    required this.status,
    required this.address,
    required this.description,
    required this.houseRules,
    required this.imageUrls,
    required this.amenities,
    this.floor,
    this.cost,
    this.availableDate,
    this.lastConfirmedAt,
    this.publishedAt,
    this.landlordName,
    this.viewsCount = 0,
  });

  factory RoomDetail.fromJson(Map<String, dynamic> json) {
    final images = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => item['public_url'] as String? ?? item['url'] as String?)
        .whereType<String>()
        .toList();
    final fallbackImage = json['image_url'] as String?;
    if (images.isEmpty && fallbackImage != null) images.add(fallbackImage);

    final amenities = (json['amenities'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => item['name'] as String?)
        .whereType<String>()
        .toList();
    final property = json['property'] as Map<String, dynamic>?;
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
      priceMonthly: (json['price_monthly'] as num?)?.toInt() ?? 0,
      depositAmount: (json['deposit_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'UNKNOWN',
      address: address,
      description: json['description'] as String? ?? 'Chưa có mô tả.',
      houseRules: json['house_rules'] as String? ?? 'Chưa có nội quy.',
      imageUrls: images,
      amenities: amenities,
      cost: json['cost'] is Map<String, dynamic>
          ? RoomCost.fromJson(json['cost'] as Map<String, dynamic>)
          : null,
      availableDate: DateTime.tryParse(json['available_date'] as String? ?? ''),
      lastConfirmedAt: DateTime.tryParse(
        json['last_confirmed_at'] as String? ?? '',
      ),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      landlordName: json['landlord_name'] as String?,
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
  final int depositAmount;
  final String status;
  final String address;
  final String description;
  final String houseRules;
  final List<String> imageUrls;
  final List<String> amenities;
  final RoomCost? cost;
  final DateTime? availableDate;
  final DateTime? lastConfirmedAt;
  final DateTime? publishedAt;
  final String? landlordName;
  final int viewsCount;
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
