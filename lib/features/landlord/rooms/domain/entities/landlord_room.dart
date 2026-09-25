class LandlordRoom {
  const LandlordRoom({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.roomType,
    required this.areaM2,
    required this.maxPeople,
    required this.priceMonthly,
    required this.depositAmount,
    required this.availableDate,
    required this.status,
    required this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
    this.floor,
    this.rejectionReason,
    this.imageUrl,
    this.propertyName,
    this.addressText,
    this.district,
    this.province,
    this.lastConfirmedAt,
  });

  factory LandlordRoom.fromJson(Map<String, dynamic> json) => LandlordRoom(
    id: json['id'] as String,
    propertyId: json['property_id'] as String,
    title: json['title'] as String? ?? 'Phòng chưa có tên',
    roomType: json['room_type'] as String? ?? 'UNKNOWN',
    areaM2: (json['area_m2'] as num?)?.toDouble() ?? 0,
    floor: (json['floor'] as num?)?.toInt(),
    maxPeople: (json['max_people'] as num?)?.toInt() ?? 0,
    priceMonthly: (json['price_monthly'] as num?)?.toInt() ?? 0,
    depositAmount: (json['deposit_amount'] as num?)?.toInt() ?? 0,
    availableDate: DateTime.parse(json['available_date'] as String),
    status: json['status'] as String? ?? 'DRAFT',
    rejectionReason: json['rejection_reason'] as String?,
    viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
    imageUrl: json['image_url'] as String?,
    propertyName: json['property_name'] as String?,
    addressText: json['address_text'] as String?,
    district: json['district'] as String?,
    province: json['province'] as String?,
    lastConfirmedAt: DateTime.tryParse(
      json['last_confirmed_at'] as String? ?? '',
    ),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  final String id, propertyId, title, roomType, status;
  final double areaM2;
  final int? floor;
  final int maxPeople, priceMonthly, depositAmount, viewsCount;
  final DateTime availableDate, createdAt, updatedAt;
  final DateTime? lastConfirmedAt;
  final String? rejectionReason, imageUrl, propertyName;
  final String? addressText, district, province;

  String get fullAddress => [
    addressText,
    district,
    province,
  ].whereType<String>().where((item) => item.trim().isNotEmpty).join(', ');
}
