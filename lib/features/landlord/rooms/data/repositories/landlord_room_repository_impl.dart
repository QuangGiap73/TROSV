import 'package:dio/dio.dart';

import '../../domain/entities/landlord_room.dart';
import '../../domain/repositories/landlord_room_repository.dart';
import '../datasources/landlord_room_remote_data_source.dart';

class LandlordRoomRepositoryImpl implements LandlordRoomRepository {
  const LandlordRoomRepositoryImpl(this._remote);

  final LandlordRoomRemoteDataSource _remote;

  @override
  Future<List<LandlordRoom>> getRooms({String? status, String? propertyId}) {
    return _execute(
      () => _remote.getRooms(status: status, propertyId: propertyId),
    );
  }

  @override
  Future<void> deleteRoom(String roomId) {
    return _execute(() => _remote.deleteRoom(roomId));
  }

  @override
  Future<void> updateVisibility(String roomId, {required bool visible}) {
    return _execute(() => _remote.updateVisibility(roomId, visible: visible));
  }

  @override
  Future<void> submitRoom(String roomId) {
    return _execute(() => _remote.submitRoom(roomId));
  }

  @override
  Future<void> confirmAvailability(String roomId) {
    return _execute(() => _remote.confirmAvailability(roomId));
  }

  @override
  Future<void> markRented(String roomId) {
    return _execute(() => _remote.markRented(roomId));
  }

  @override
  Future<void> unmarkRented(String roomId) {
    return _execute(() => _remote.unmarkRented(roomId));
  }

  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw LandlordRoomFailure(_dioMessage(error));
    } on FormatException catch (error) {
      throw LandlordRoomFailure(error.message);
    } on TypeError {
      throw const LandlordRoomFailure(
        'Dữ liệu phòng từ máy chủ không đúng định dạng.',
      );
    }
  }
}

String _dioMessage(DioException error) {
  final body = error.response?.data;
  if (body is Map<String, dynamic>) {
    final apiError = body['error'];
    if (apiError is Map<String, dynamic> && apiError['message'] is String) {
      return apiError['message'] as String;
    }
    if (body['message'] is String) return body['message'] as String;
  }

  return switch (error.response?.statusCode) {
    401 => 'Phiên đăng nhập đã hết hạn.',
    403 => 'Tài khoản chưa ở chế độ chủ trọ.',
    404 => 'Không tìm thấy phòng.',
    _ => 'Không thể kết nối đến dịch vụ phòng trọ.',
  };
}
