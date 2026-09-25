class UniversityLocation {
  const UniversityLocation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.address,
    required this.district,
    required this.latitude,
    required this.longitude,
  });

  factory UniversityLocation.fromJson(Map<String, dynamic> json) {
    return UniversityLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String shortName;
  final String address;
  final String district;
  final double latitude;
  final double longitude;

  String get label => '$name $shortName $district $address';
}
