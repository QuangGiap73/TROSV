class LandlordProperty {
  const LandlordProperty({
    required this.id,
    required this.name,
    required this.addressText,
    required this.province,
    required this.district,
    required this.ward,
    required this.latitude,
    required this.longitude,
  });
  factory LandlordProperty.fromJson(Map<String, dynamic> json) =>
      LandlordProperty(
        id: json['id'] as String,
        name: json['name'] as String,
        addressText: json['address_text'] as String,
        province: json['province'] as String,
        district: json['district'] as String? ?? '',
        ward: json['ward'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
  final String id, name, addressText, province, district, ward;
  final double latitude, longitude;
}

class AmenityOption {
  const AmenityOption({
    required this.id,
    required this.code,
    required this.name,
    this.icon,
  });
  factory AmenityOption.fromJson(Map<String, dynamic> json) => AmenityOption(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String?,
  );
  final String id, code, name;
  final String? icon;
}

class UploadedRoomMedia {
  const UploadedRoomMedia({
    required this.url,
    required this.objectKey,
    required this.mediaType,
    this.thumbnailUrl,
  });
  factory UploadedRoomMedia.fromJson(Map<String, dynamic> json) =>
      UploadedRoomMedia(
        url: json['url'] as String,
        objectKey: json['object_key'] as String,
        mediaType: json['media_type'] as String? ?? 'IMAGE',
        thumbnailUrl: json['thumbnail_url'] as String?,
      );
  final String url, objectKey, mediaType;
  final String? thumbnailUrl;
  Map<String, dynamic> toRoomImageJson({required bool isPrimary}) => {
    'url': url,
    'thumbnail_url': thumbnailUrl,
    'object_key': objectKey,
    'space': 'MAIN_ROOM',
    'isPrimary': isPrimary,
    'media_type': mediaType,
  };
}
