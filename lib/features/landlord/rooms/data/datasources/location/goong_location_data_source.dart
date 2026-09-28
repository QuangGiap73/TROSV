import 'package:dio/dio.dart';

import '../../../domain/entities/location/geocoded_address.dart';

class GoongLocationDataSource {
  const GoongLocationDataSource(this._dio);

  final Dio _dio;

  Future<GeocodedAddress> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/Geocode',
      queryParameters: {
        'latlng': '$latitude,$longitude',
      },
    );

    final first = _firstResult(response.data);
    return _parseAddress(first);
  }

  Future<GeocodedLocation> forwardGeocode({
    required String address,
  }) async {
    final query = address.trim();

    if (query.length < 5) {
      throw const FormatException(
        'Địa chỉ quá ngắn để tìm vị trí.',
      );
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/Geocode',
      queryParameters: {
        'address': query,
      },
    );

    final first = _firstResult(response.data);

    final rawGeometry = first['geometry'];
    if (rawGeometry is! Map) {
      throw const FormatException(
        'Goong không trả về thông tin tọa độ.',
      );
    }

    final geometry = Map<String, dynamic>.from(rawGeometry);

    final rawLocation = geometry['location'];
    if (rawLocation is! Map) {
      throw const FormatException(
        'Goong không trả về vị trí hợp lệ.',
      );
    }

    final location = Map<String, dynamic>.from(rawLocation);
    final latitude = (location['lat'] as num?)?.toDouble();
    final longitude = (location['lng'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      throw const FormatException(
        'Tọa độ Goong trả về không hợp lệ.',
      );
    }

    return GeocodedLocation(
      latitude: latitude,
      longitude: longitude,
      address: _parseAddress(first),
    );
  }

  Map<String, dynamic> _firstResult(
    Map<String, dynamic>? data,
  ) {
    final results = data?['results'];

    if (results is! List || results.isEmpty) {
      throw const FormatException(
        'Không tìm thấy địa chỉ phù hợp.',
      );
    }

    final first = results.first;

    if (first is! Map) {
      throw const FormatException(
        'Dữ liệu địa chỉ Goong không hợp lệ.',
      );
    }

    return Map<String, dynamic>.from(first);
  }

  GeocodedAddress _parseAddress(
    Map<String, dynamic> result,
  ) {
    final formatted =
        (result['formatted_address'] as String? ?? '').trim();

    final rawComponents = result['address_components'];

    final components = rawComponents is List
        ? rawComponents
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    final province = _findComponent(
      components,
      const [
        'province',
        'administrative_area_level_1',
      ],
      const [
        'tỉnh ',
        'thành phố ',
      ],
    );

    final district = _findComponent(
      components,
      const [
        'district',
        'administrative_area_level_2',
      ],
      const [
        'quận ',
        'huyện ',
        'thị xã ',
        'thành phố ',
      ],
    );

    final ward = _findComponent(
      components,
      const [
        'ward',
        'administrative_area_level_3',
        'sublocality',
      ],
      const [
        'phường ',
        'xã ',
        'thị trấn ',
      ],
    );

    final names = components
        .map(
          (item) =>
              (item['long_name'] as String? ?? '').trim(),
        )
        .where((name) => name.isNotEmpty)
        .toList();

    return GeocodedAddress(
      formattedAddress: formatted.isNotEmpty
          ? formatted
          : names.join(', '),
      province: province.isNotEmpty
          ? province
          : names.isNotEmpty
              ? names.last
              : '',
      district: district.isNotEmpty
          ? district
          : names.length >= 2
              ? names[names.length - 2]
              : '',
      ward: ward.isNotEmpty
          ? ward
          : names.length >= 3
              ? names[names.length - 3]
              : '',
    );
  }
}

String _findComponent(
  List<Map<String, dynamic>> components,
  List<String> acceptedTypes,
  List<String> acceptedPrefixes,
) {
  for (final component in components) {
    final types =
        (component['types'] as List?)?.whereType<String>() ??
            const <String>[];

    if (types.any(acceptedTypes.contains)) {
      return (component['long_name'] as String? ?? '').trim();
    }
  }

  for (final component in components.reversed) {
    final name =
        (component['long_name'] as String? ?? '').trim();

    final lower = name.toLowerCase();

    if (acceptedPrefixes.any(lower.startsWith)) {
      return name;
    }
  }

  return '';
}
