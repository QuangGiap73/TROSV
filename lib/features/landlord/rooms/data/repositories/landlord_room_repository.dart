import 'package:dio/dio.dart';
import '../../domain/entities/landlord_room.dart';
import '../datasources/landlord_room_remote_data_source.dart';

class LandlordRoomRepository {
  const LandlordRoomRepository(this._remote);
  final LandlordRoomRemoteDataSource _remote;

  Future<List<LandlordRoom>> getRooms({String? status}) async {
    try {
      return await _remote.getRooms(status: status);
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map<String, dynamic>) {
        final apiError = body['error'];
        if (apiError is Map<String, dynamic> && apiError['message'] is String) {
          throw Exception(apiError['message']);
        }
      }
      if (error.response?.statusCode == 403) {
        throw Exception('Tài khoản chưa ở chế độ chủ trọ.');
      }
      throw Exception('Không thể tải danh sách phòng.');
    } on FormatException catch (error) {
      throw Exception(error.message);
    }
  }
}
