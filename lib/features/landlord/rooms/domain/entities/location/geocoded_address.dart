class GeocodedAddress {
  const GeocodedAddress({
    required this.formattedAddress,
    required this.province,
    required this.district,
    required this.ward,
  });

  final String formattedAddress;
  final String province;
  final String district;
  final String ward;
}

class GeocodedLocation {
  const GeocodedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final GeocodedAddress address;
}

typedef LocationCoordinates = ({
  double latitude,
  double longitude,
});
