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

typedef LocationCoordinates = ({double latitude, double longitude});
