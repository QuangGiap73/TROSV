class UniversityItem {
  const UniversityItem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.searchQuery,
    required this.imageAsset,
    this.defaultRadiusMeters = 5000,
  });

  final String id;
  final String name;
  final String shortName;

  /// Chuỗi dùng để resolve trường qua Goong/Places trước khi gọi API phòng.
  /// Cố tình không hard-code lat/lng để tránh tọa độ sai hoặc lỗi thời.
  final String searchQuery;

  /// Ảnh card trường trong Home.
  final String imageAsset;

  /// Bán kính mặc định khi tìm trọ quanh trường.
  final int defaultRadiusMeters;
}
