import 'package:dio/dio.dart';
import '../../domain/entities/landlord_room.dart';
import '../../domain/entities/landlord_room_detail.dart';

class LandlordRoomRemoteDataSource {
  const LandlordRoomRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<LandlordRoom>> getRooms({
    String? status,
    String? propertyId,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (status != null) queryParameters['status'] = status;
    if (propertyId != null) queryParameters['property_id'] = propertyId;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/landlord/rooms',
      queryParameters: queryParameters,
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! List) {
      throw const FormatException('Danh sách phòng của chủ trọ không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(LandlordRoom.fromJson)
        .toList(growable: false);
  }

  Future<LandlordRoomDetail> getRoomDetail(String roomId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId',
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException(
        'Chi tiết phòng từ máy chủ không đúng định dạng.',
      );
    }
    return LandlordRoomDetail.fromJson(data);
  }

  Future<void> deleteRoom(String roomId) async {
    await _dio.delete<Map<String, dynamic>>('/api/v1/landlord/rooms/$roomId');
  }

  Future<void> updateVisibility(String roomId, {required bool visible}) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId/visibility',
      data: {'visible': visible},
    );
  }

  Future<void> submitRoom(String roomId) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId/submit',
    );
  }

  Future<void> confirmAvailability(String roomId) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId/confirm-availability',
    );
  }

  Future<void> markRented(String roomId) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId/mark-rented',
    );
  }

  Future<void> unmarkRented(String roomId) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId/unmark-rented',
    );
  }
}
