class LandlordRoomDetail {
  const LandlordRoomDetail({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.roomType,
    required this.areaM2,
    required this.maxPeople,
    required this.priceMonthly,
    required this.depositAmount,
    required this.status,
    required this.viewsCount,
    required this.spaces,
    required this.media,
    required this.amenities,
    this.floor,
    this.availableDate,
    this.description,
    this.houseRules,
    this.rejectionReason,
    this.imageUrl,
    this.propertyName,
    this.addressText,
    this.district,
    this.province,
    this.publishedAt,
    this.lastConfirmedAt,
    this.createdAt,
    this.updatedAt,
    this.property,
    this.cost,
  });

  factory LandlordRoomDetail.fromJson(Map<String, dynamic> json) {
    return LandlordRoomDetail(
      id: _string(json['id']),
      propertyId: _string(json['property_id']),
      title: _string(json['title'], fallback: 'Phòng chưa có tên'),
      roomType: _string(json['room_type'], fallback: 'UNKNOWN'),
      areaM2: _double(json['area_m2']),
      floor: _nullableInt(json['floor']),
      maxPeople: _int(json['max_people']),
      priceMonthly: _int(json['price_monthly']),
      depositAmount: _int(json['deposit_amount']),
      availableDate: _date(json['available_date']),
      status: _string(json['status'], fallback: 'DRAFT'),
      description: _nullableString(json['description']),
      houseRules: _nullableString(json['house_rules']),
      rejectionReason: _nullableString(json['rejection_reason']),
      viewsCount: _int(json['views_count']),
      imageUrl: _nullableString(json['image_url']),
      propertyName: _nullableString(json['property_name']),
      addressText: _nullableString(json['address_text']),
      district: _nullableString(json['district']),
      province: _nullableString(json['province']),
      publishedAt: _date(json['published_at']),
      lastConfirmedAt: _date(json['last_confirmed_at']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      property: _map(json['property'], LandlordPropertyDetail.fromJson),
      spaces: _list(json['spaces'], LandlordRoomSpace.fromJson),
      media: _list(json['media'], LandlordRoomMedia.fromJson),
      cost: _map(json['cost'], LandlordRoomCost.fromJson),
      amenities: _list(json['amenities'], LandlordRoomAmenity.fromJson),
    );
  }

  final String id, propertyId, title, roomType, status;
  final double areaM2;
  final int? floor;
  final int maxPeople, priceMonthly, depositAmount, viewsCount;
  final DateTime? availableDate,
      publishedAt,
      lastConfirmedAt,
      createdAt,
      updatedAt;
  final String? description, houseRules, rejectionReason, imageUrl;
  final String? propertyName, addressText, district, province;
  final LandlordPropertyDetail? property;
  final List<LandlordRoomSpace> spaces;
  final List<LandlordRoomMedia> media;
  final LandlordRoomCost? cost;
  final List<LandlordRoomAmenity> amenities;

  String get fullAddress {
    final values = property == null
        ? [addressText, district, province]
        : [
            property!.addressText,
            property!.ward,
            property!.district,
            property!.province,
          ];
    return _uniqueText(values).join(', ');
  }

  List<LandlordRoomMedia> get images =>
      media.where((item) => !item.isVideo).toList(growable: false)
        ..sort((a, b) {
          if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
          return a.sortOrder.compareTo(b.sortOrder);
        });

  List<LandlordRoomMedia> get videos =>
      media.where((item) => item.isVideo).toList(growable: false);
}

class LandlordPropertyDetail {
  const LandlordPropertyDetail({
    required this.id,
    required this.landlordId,
    required this.name,
    required this.addressText,
    required this.province,
    required this.district,
    required this.ward,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.description,
    this.createdAt,
  });

  factory LandlordPropertyDetail.fromJson(Map<String, dynamic> json) =>
      LandlordPropertyDetail(
        id: _string(json['id']),
        landlordId: _string(json['landlord_id']),
        name: _string(json['name']),
        addressText: _string(json['address_text']),
        province: _string(json['province']),
        district: _string(json['district']),
        ward: _string(json['ward']),
        latitude: _double(json['latitude']),
        longitude: _double(json['longitude']),
        description: _nullableString(json['description']),
        status: _string(json['status']),
        createdAt: _date(json['created_at']),
      );

  final String id,
      landlordId,
      name,
      addressText,
      province,
      district,
      ward,
      status;
  final double latitude, longitude;
  final String? description;
  final DateTime? createdAt;
}

class LandlordRoomSpace {
  const LandlordRoomSpace({
    required this.id,
    required this.roomId,
    required this.spaceType,
    required this.privacyType,
    this.description,
  });
  factory LandlordRoomSpace.fromJson(Map<String, dynamic> json) =>
      LandlordRoomSpace(
        id: _string(json['id']),
        roomId: _string(json['room_id']),
        spaceType: _string(json['space_type']),
        privacyType: _string(json['privacy_type']),
        description: _nullableString(json['description']),
      );
  final String id, roomId, spaceType, privacyType;
  final String? description;
}

class LandlordRoomMedia {
  const LandlordRoomMedia({
    required this.id,
    required this.roomId,
    required this.mediaType,
    required this.isPrimary,
    required this.sortOrder,
    this.spaceId,
    this.url,
    this.publicUrl,
    this.objectKey,
    this.thumbnailUrl,
  });
  factory LandlordRoomMedia.fromJson(Map<String, dynamic> json) =>
      LandlordRoomMedia(
        id: _string(json['id']),
        roomId: _string(json['room_id']),
        spaceId: _nullableString(json['space_id']),
        mediaType: _string(json['media_type']),
        url: _nullableString(json['url']),
        publicUrl: _nullableString(json['public_url']),
        objectKey: _nullableString(json['object_key']),
        thumbnailUrl: _nullableString(json['thumbnail_url']),
        isPrimary: json['is_primary'] == true,
        sortOrder: _int(json['sort_order']),
      );
  final String id, roomId, mediaType;
  final String? spaceId, url, publicUrl, objectKey, thumbnailUrl;
  final bool isPrimary;
  final int sortOrder;
  String? get displayUrl => _nullableString(publicUrl) ?? _nullableString(url);
  bool get isVideo {
    if (mediaType.toUpperCase() == 'VIDEO') return true;
    final value = displayUrl ?? objectKey;
    if (value == null || value.trim().isEmpty) return false;
    final path =
        Uri.tryParse(value.trim())?.path.toLowerCase() ??
        value.trim().toLowerCase();
    return const ['.mp4', '.m4v', '.mov', '.webm', '.3gp'].any(path.endsWith);
  }
}

class LandlordRoomCost {
  const LandlordRoomCost({
    required this.id,
    required this.roomId,
    required this.electricityPrice,
    required this.waterPrice,
    required this.internetFee,
    required this.parkingFee,
    required this.serviceFee,
    required this.cleaningFee,
    required this.otherFee,
    this.electricityType,
    this.waterType,
    this.otherDescription,
  });
  factory LandlordRoomCost.fromJson(Map<String, dynamic> json) =>
      LandlordRoomCost(
        id: _string(json['id']),
        roomId: _string(json['room_id']),
        electricityType: _nullableString(json['electricity_type']),
        electricityPrice: _int(json['electricity_price']),
        waterType: _nullableString(json['water_type']),
        waterPrice: _int(json['water_price']),
        internetFee: _int(json['internet_fee']),
        parkingFee: _int(json['parking_fee']),
        serviceFee: _int(json['service_fee']),
        cleaningFee: _int(json['cleaning_fee']),
        otherFee: _int(json['other_fee']),
        otherDescription: _nullableString(json['other_description']),
      );
  final String id, roomId;
  final String? electricityType, waterType, otherDescription;
  final int electricityPrice,
      waterPrice,
      internetFee,
      parkingFee,
      serviceFee,
      cleaningFee,
      otherFee;
}

class LandlordRoomAmenity {
  const LandlordRoomAmenity({
    required this.id,
    required this.code,
    required this.name,
    this.icon,
  });
  factory LandlordRoomAmenity.fromJson(Map<String, dynamic> json) =>
      LandlordRoomAmenity(
        id: _string(json['id']),
        code: _string(json['code']),
        name: _string(json['name']),
        icon: _nullableString(json['icon']),
      );
  final String id, code, name;
  final String? icon;
}

String _string(dynamic value, {String fallback = ''}) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;
String? _nullableString(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
int? _nullableInt(dynamic value) => value == null
    ? null
    : (value is num ? value.toInt() : int.tryParse(value.toString()));
double _double(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
T? _map<T>(dynamic value, T Function(Map<String, dynamic>) parser) =>
    value is Map<String, dynamic> ? parser(value) : null;
List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) parser) =>
    value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(parser)
          .toList(growable: false)
    : const [];
List<String> _uniqueText(Iterable<String?> values) => values
    .whereType<String>()
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toSet()
    .toList(growable: false);
