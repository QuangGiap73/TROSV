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
      queryParameters: {'latlng': '$latitude,$longitude'},
    );
    final results = response.data?['results'];
    if (results is! List || results.isEmpty) {
      throw const FormatException('Không tìm thấy địa chỉ tại vị trí này.');
    }

    final first = results.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu địa chỉ Goong không hợp lệ.');
    }
    final formatted = (first['formatted_address'] as String? ?? '').trim();
    final rawComponents = first['address_components'];
    final components = rawComponents is List
        ? rawComponents.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    final province = _findComponent(
      components,
      const ['province', 'administrative_area_level_1'],
      const ['tỉnh ', 'thành phố '],
    );
    final district = _findComponent(
      components,
      const ['district', 'administrative_area_level_2'],
      const ['quận ', 'huyện ', 'thị xã '],
    );
    final ward = _findComponent(
      components,
      const ['ward', 'administrative_area_level_3', 'sublocality'],
      const ['phường ', 'xã ', 'thị trấn '],
    );
    final names = components
        .map((item) => (item['long_name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();

    return GeocodedAddress(
      formattedAddress: formatted.isNotEmpty ? formatted : names.join(', '),
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
        (component['types'] as List?)?.whereType<String>() ?? const [];
    if (types.any(acceptedTypes.contains)) {
      return (component['long_name'] as String? ?? '').trim();
    }
  }
  for (final component in components.reversed) {
    final name = (component['long_name'] as String? ?? '').trim();
    final lower = name.toLowerCase();
    if (acceptedPrefixes.any(lower.startsWith)) return name;
  }
  return '';
}
