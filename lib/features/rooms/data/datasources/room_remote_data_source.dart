import 'package:dio/dio.dart';

import '../../domain/entities/room_detail.dart';
import '../../domain/entities/room_summary.dart';

class RoomRemoteDataSource {
  const RoomRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<RoomSummary>> getRooms({required int limit}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rooms',
      queryParameters: {'page': 1, 'limit': limit},
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! List) {
      throw const FormatException('Dữ liệu danh sách phòng không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(RoomSummary.fromJson)
        .toList();
  }

  Future<RoomDetail> getRoomDetail(String roomId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rooms/$roomId',
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu chi tiết phòng không hợp lệ.');
    }
    return RoomDetail.fromJson(data);
  }

  Future<void> addFavorite(String roomId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rooms/$roomId/favorite',
    );
    if (response.data?['success'] != true) {
      throw const FormatException('Không thể lưu phòng yêu thích.');
    }
  }

  Future<List<RoomSummary>> getFavorites({
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/me/favorites',
      queryParameters: {'page': page, 'limit': limit},
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! List) {
      throw const FormatException('Dữ liệu yêu thích không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(RoomSummary.fromJson)
        .toList();
  }

  Future<void> removeFavorite(String roomId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/rooms/$roomId/favorite',
    );
    if (response.data?['success'] != true) {
      throw const FormatException('Không thể bỏ phòng yêu thích.');
    }
  }
}
