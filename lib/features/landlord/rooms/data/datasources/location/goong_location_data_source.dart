import 'package:dio/dio.dart';

import '../../../domain/entities/location/geocoded_address.dart';

class GoongLocationDataSource {
  const GoongLocationDataSource(this._dio);

  final Dio _dio;

  /// Map -> địa chỉ.
  ///
  /// Chỉ nên gọi khi người dùng dừng kéo map.
  Future<GeocodedAddress> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/geocode',
      queryParameters: {
        'latlng': '$latitude,$longitude',
        'limit': 1,
        'has_deprecated_administrative_unit': true,
      },
    );

    final first = _firstGeocodeResult(response.data);

    return _parseAddress(first);
  }

  /// Fallback: địa chỉ đầy đủ -> tọa độ.
  ///
  /// Không dùng hàm này để tự động nhảy map khi user đang gõ.
  Future<GeocodedLocation> forwardGeocode({
    required String address,
  }) async {
    final query = address.trim();

    if (query.length < 3) {
      throw const FormatException(
        'Địa chỉ quá ngắn để tìm vị trí.',
      );
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/geocode',
      queryParameters: {
        'address': query,
        'has_deprecated_administrative_unit': true,
      },
    );

    final first = _firstGeocodeResult(response.data);

    return _locationFromResult(first);
  }

  /// User đang gõ -> chỉ trả danh sách gợi ý.
  ///
  /// Hàm này KHÔNG thay đổi text, KHÔNG thay đổi map.
  Future<List<GoongPlacePrediction>> autocomplete({
    required String input,
    int limit = 5,
  }) async {
    final query = input.trim();

    if (query.length < 2) {
      return const [];
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/place/autocomplete',
      queryParameters: {
        'input': query,
        'limit': limit,
        'more_compound': true,
        'has_deprecated_administrative_unit': true,
      },
    );

    final rawPredictions = response.data?['predictions'];

    if (rawPredictions is! List) {
      return const [];
    }

    return rawPredictions
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);

          final placeId =
              (item['place_id'] as String? ?? '').trim();

          final description =
              (item['description'] as String? ?? '').trim();

          final rawFormatting = item['structured_formatting'];

          final formatting = rawFormatting is Map
              ? Map<String, dynamic>.from(rawFormatting)
              : <String, dynamic>{};

          final mainText =
              (formatting['main_text'] as String? ?? '').trim();

          final secondaryText =
              (formatting['secondary_text'] as String? ?? '').trim();

          return GoongPlacePrediction(
            placeId: placeId,
            description: description,
            mainText: mainText.isNotEmpty ? mainText : description,
            secondaryText: secondaryText,
          );
        })
        .where(
          (item) =>
              item.placeId.isNotEmpty &&
              item.description.isNotEmpty,
        )
        .toList(growable: false);
  }

  /// Chỉ gọi sau khi user chủ động bấm một suggestion.
  Future<GeocodedLocation> placeDetail({
    required String placeId,
  }) async {
    final id = placeId.trim();

    if (id.isEmpty) {
      throw const FormatException(
        'place_id không hợp lệ.',
      );
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/place/detail',
      queryParameters: {
        'place_id': id,
        'has_deprecated_administrative_unit': true,
      },
    );

    final rawResult = response.data?['result'];

    if (rawResult is! Map) {
      throw const FormatException(
        'Không lấy được chi tiết địa điểm.',
      );
    }

    final result = Map<String, dynamic>.from(rawResult);

    return _locationFromResult(result);
  }

  Map<String, dynamic> _firstGeocodeResult(
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
        'Dữ liệu Goong không hợp lệ.',
      );
    }

    return Map<String, dynamic>.from(first);
  }

  GeocodedLocation _locationFromResult(
    Map<String, dynamic> result,
  ) {
    final rawGeometry = result['geometry'];

    if (rawGeometry is! Map) {
      throw const FormatException(
        'Goong không trả về tọa độ.',
      );
    }

    final geometry = Map<String, dynamic>.from(rawGeometry);
    final rawLocation = geometry['location'];

    if (rawLocation is! Map) {
      throw const FormatException(
        'Vị trí Goong không hợp lệ.',
      );
    }

    final location = Map<String, dynamic>.from(rawLocation);

    final latitude = (location['lat'] as num?)?.toDouble();
    final longitude = (location['lng'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      throw const FormatException(
        'Tọa độ Goong không hợp lệ.',
      );
    }

    return GeocodedLocation(
      latitude: latitude,
      longitude: longitude,
      address: _parseAddress(result),
    );
  }

  GeocodedAddress _parseAddress(
    Map<String, dynamic> result,
  ) {
    final formattedAddress =
        (result['formatted_address'] as String? ?? '').trim();

    final compound = _mapOrEmpty(result['compound']);
    final deprecatedCompound =
        _mapOrEmpty(result['deprecated_compound']);

    // V2 ưu tiên địa giới hiện hành.
    final province = _firstNonEmpty([
      compound['province'],
      deprecatedCompound['province'],
    ]);

    final ward = _firstNonEmpty([
      compound['commune'],
      compound['ward'],
      deprecatedCompound['commune'],
      deprecatedCompound['ward'],
    ]);

    // Backend hiện tại của app vẫn có field district.
    // V2 có thể không trả district trong compound hiện hành,
    // nên dùng deprecated_compound làm dữ liệu tương thích nếu có.
    final district = _firstNonEmpty([
      compound['district'],
      deprecatedCompound['district'],
    ]);

    return GeocodedAddress(
      formattedAddress: formattedAddress,
      province: province,
      district: district,
      ward: ward,
    );
  }

  Map<String, dynamic> _mapOrEmpty(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }
}
