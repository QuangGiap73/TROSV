import 'package:dio/dio.dart';
import '../../domain/entities/landlord_room.dart';

class LandlordRoomRemoteDataSource {
  const LandlordRoomRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<LandlordRoom>> getRooms({String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/landlord/rooms',
      queryParameters: status == null ? null : {'status': status},
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
}
