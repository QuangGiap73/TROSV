import 'package:dio/dio.dart';

import '../../domain/entities/amenity.dart';
import '../../domain/entities/tenant_preference.dart';

class PreferenceRemoteDataSource {
  const PreferenceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TenantPreference?> getMyPreference() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/me/preferences',
    );

    final envelope = response.data;

    if (envelope?['success'] != true) {
      throw const FormatException('Không thể đọc nhu cầu tìm trọ.');
    }

    final data = envelope?['data'];

    // Người dùng chưa thiết lập nhu cầu.
    if (data == null) return null;

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu nhu cầu tìm trọ không hợp lệ.');
    }

    return TenantPreference.fromJson(data);
  }

  Future<TenantPreference> saveMyPreference(TenantPreference preference) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/me/preferences',
      data: preference.toRequestJson(),
    );

    final envelope = response.data;
    final data = envelope?['data'];

    if (envelope?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Không thể lưu nhu cầu tìm trọ.');
    }

    return TenantPreference.fromJson(data);
  }

  Future<List<Amenity>> getAmenities() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/amenities');

    final envelope = response.data;
    final data = envelope?['data'];

    if (envelope?['success'] != true || data is! List) {
      throw const FormatException('Danh sách tiện ích không hợp lệ.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Amenity.fromJson)
        .toList();
  }
}
