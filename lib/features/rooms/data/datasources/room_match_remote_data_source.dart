import 'package:dio/dio.dart';

import '../../../preferences/domain/entities/tenant_preference.dart';
import '../../domain/entities/room_match.dart';

class RoomMatchRemoteDataSource {
  const RoomMatchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RoomMatch>> matchRooms(
    TenantPreference preference, {
    int limit = 10,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rooms/match',
      data: preference.toMatchRequestJson(limit: limit),
    );

    final envelope = response.data;
    final data = envelope?['data'];

    if (envelope?['success'] != true || data is! List) {
      throw const FormatException('Danh sách phòng phù hợp không hợp lệ.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(RoomMatch.fromJson)
        .toList();
  }
}
