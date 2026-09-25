class Amenity {
  const Amenity({
    required this.id,
    required this.code,
    required this.name,
    this.icon,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? icon;
}
