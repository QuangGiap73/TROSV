import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/landlord_room_remote_data_source.dart';
import '../../data/repositories/landlord_room_repository_impl.dart';
import '../../domain/entities/landlord_room.dart';
import '../../domain/entities/landlord_room_detail.dart';
import '../../domain/repositories/landlord_room_repository.dart';

final landlordRoomRemoteDataSourceProvider =
    Provider<LandlordRoomRemoteDataSource>((ref) {
      return LandlordRoomRemoteDataSource(ref.watch(dioProvider));
    });

final landlordRoomRepositoryProvider = Provider<LandlordRoomRepository>((ref) {
  return LandlordRoomRepositoryImpl(
    ref.watch(landlordRoomRemoteDataSourceProvider),
  );
});

/// Danh sách phòng theo trạng thái.
/// Giữ autoDispose vì màn danh sách có thể dùng nhiều bộ lọc khác nhau.
final landlordRoomsProvider = FutureProvider.family
    .autoDispose<List<LandlordRoom>, String?>((ref, status) {
      return ref.watch(landlordRoomRepositoryProvider).getRooms(status: status);
    });

/// Nguồn dữ liệu duy nhất cho cả:
/// - màn Tổng quan phòng
/// - màn Chi tiết 4 tab
///
/// Hai route cùng watch provider theo roomId nên Riverpod không cần tạo thêm
/// một state model khác cho cùng một phòng.
final landlordRoomDetailProvider = FutureProvider.autoDispose
    .family<LandlordRoomDetail, String>((ref, roomId) {
      return ref.watch(landlordRoomRepositoryProvider).getRoomDetail(roomId);
    });
