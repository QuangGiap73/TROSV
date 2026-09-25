class RoomSearchQuery {
  const RoomSearchQuery({
    this.keyword,
    this.district,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.roomType,
    this.amenityCodes = const [],
    this.bathroomPrivate,
    this.hasBalcony,
    this.sort = 'RELEVANCE',
    this.page = 1,
    this.limit = 50,
  });

  final String? keyword;
  final String? district;
  final int? minPrice;
  final int? maxPrice;
  final double? minArea;
  final double? maxArea;
  final String? roomType;
  final List<String> amenityCodes;
  final bool? bathroomPrivate;
  final bool? hasBalcony;
  final String sort;
  final int page;
  final int limit;

  RoomSearchQuery copyWith({
    String? keyword,
    bool clearKeyword = false,
    String? district,
    bool clearDistrict = false,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    double? minArea,
    double? maxArea,
    bool clearArea = false,
    String? roomType,
    bool clearRoomType = false,
    List<String>? amenityCodes,
    bool? bathroomPrivate,
    bool clearBathroomPrivate = false,
    bool? hasBalcony,
    bool clearHasBalcony = false,
    String? sort,
    int? page,
    int? limit,
  }) {
    return RoomSearchQuery(
      keyword: clearKeyword ? null : keyword ?? this.keyword,
      district: clearDistrict ? null : district ?? this.district,
      minPrice: clearPrice ? minPrice : minPrice ?? this.minPrice,
      maxPrice: clearPrice ? maxPrice : maxPrice ?? this.maxPrice,
      minArea: clearArea ? minArea : minArea ?? this.minArea,
      maxArea: clearArea ? maxArea : maxArea ?? this.maxArea,
      roomType: clearRoomType ? null : roomType ?? this.roomType,
      amenityCodes: amenityCodes ?? this.amenityCodes,
      bathroomPrivate: clearBathroomPrivate
          ? null
          : bathroomPrivate ?? this.bathroomPrivate,
      hasBalcony: clearHasBalcony ? null : hasBalcony ?? this.hasBalcony,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParameters() => {
    'page': page,
    'limit': limit,
    'sort': sort,
    if (keyword?.trim().isNotEmpty == true) 'keyword': keyword!.trim(),
    if (district != null) 'district': district,
    if (minPrice != null) 'min_price': minPrice,
    if (maxPrice != null) 'max_price': maxPrice,
    if (minArea != null) 'min_area': minArea,
    if (maxArea != null) 'max_area': maxArea,
    if (roomType != null) 'room_type': roomType,
    if (amenityCodes.isNotEmpty) 'amenities': amenityCodes.join(','),
    if (bathroomPrivate != null) 'bathroom_private': bathroomPrivate,
    if (hasBalcony != null) 'has_balcony': hasBalcony,
  };

  @override
  bool operator ==(Object other) {
    return other is RoomSearchQuery &&
        other.keyword == keyword &&
        other.district == district &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minArea == minArea &&
        other.maxArea == maxArea &&
        other.roomType == roomType &&
        _sameList(other.amenityCodes, amenityCodes) &&
        other.bathroomPrivate == bathroomPrivate &&
        other.hasBalcony == hasBalcony &&
        other.sort == sort &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(
    keyword,
    district,
    minPrice,
    maxPrice,
    minArea,
    maxArea,
    roomType,
    Object.hashAll(amenityCodes),
    bathroomPrivate,
    hasBalcony,
    sort,
    page,
    limit,
  );
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
