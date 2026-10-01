import 'package:dio/dio.dart';

class UniversityLocationDataSource {
  const UniversityLocationDataSource(this._dio);

  final Dio _dio;

  Future<({double latitude, double longitude})> resolve(
    String searchQuery,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/geocode',
      queryParameters: {
        'address': searchQuery.trim(),
        'has_deprecated_administrative_unit': true,
      },
    );
    final results = response.data?['results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      throw const FormatException('Không tìm thấy vị trí của trường.');
    }
    final result = Map<String, dynamic>.from(results.first as Map);
    final geometry = result['geometry'];
    if (geometry is! Map || geometry['location'] is! Map) {
      throw const FormatException('Goong không trả về tọa độ trường.');
    }
    final location = Map<String, dynamic>.from(geometry['location'] as Map);
    final latitude = (location['lat'] as num?)?.toDouble();
    final longitude = (location['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const FormatException('Tọa độ trường không hợp lệ.');
    }
    return (latitude: latitude, longitude: longitude);
  }
}
