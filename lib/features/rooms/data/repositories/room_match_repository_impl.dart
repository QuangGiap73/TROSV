import 'package:dio/dio.dart';

import '../../../preferences/domain/entities/tenant_preference.dart';
import '../../domain/entities/room_match.dart';
import '../../domain/repositories/room_match_repository.dart';
import '../datasources/room_match_remote_data_source.dart';

class RoomMatchRepositoryImpl implements RoomMatchRepository {
  const RoomMatchRepositoryImpl(this._remote);

  final RoomMatchRemoteDataSource _remote;

  @override
  Future<List<RoomMatch>> matchRooms(
    TenantPreference preference, {
    int limit = 10,
  }) async {
    try {
      return await _remote.matchRooms(preference, limit: limit);
    } on DioException catch (error) {
      throw RoomMatchFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw RoomMatchFailure(error.message);
    }
  }

  String _errorMessage(DioException error) {
    final body = error.response?.data;

    if (body is Map<String, dynamic>) {
      final apiError = body['error'];

      if (apiError is Map<String, dynamic> && apiError['message'] is String) {
        return apiError['message'] as String;
      }

      if (body['detail'] is String) {
        return body['detail'] as String;
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn.';
    }

    if (error.response?.statusCode == 422) {
      return 'Nhu cầu tìm phòng chưa hợp lệ.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối quá thời gian. Vui lòng thử lại.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối tới máy chủ.';
    }

    return 'Không thể tìm phòng phù hợp.';
  }
}
