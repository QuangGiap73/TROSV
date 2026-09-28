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

class GoongPlacePrediction {
  const GoongPlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
}

typedef LocationCoordinates = ({
  double latitude,
  double longitude,
});
