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

final landlordRoomsProvider = FutureProvider.family
    .autoDispose<List<LandlordRoom>, String?>((ref, status) {
      return ref.watch(landlordRoomRepositoryProvider).getRooms(status: status);
    });

final landlordRoomDetailProvider = FutureProvider.autoDispose
    .family<LandlordRoomDetail, String>((ref, roomId) {
      return ref.watch(landlordRoomRepositoryProvider).getRoomDetail(roomId);
    });

final landlordRoomActionProvider =
    AsyncNotifierProvider<LandlordRoomActionController, void>(
      LandlordRoomActionController.new,
    );

class LandlordRoomActionController extends AsyncNotifier<void> {
  LandlordRoomRepository get _repository =>
      ref.read(landlordRoomRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<bool> deleteRoom(String roomId) {
    return _run(roomId, () => _repository.deleteRoom(roomId));
  }

  Future<bool> updateVisibility(String roomId, {required bool visible}) {
    return _run(
      roomId,
      () => _repository.updateVisibility(roomId, visible: visible),
    );
  }

  Future<bool> submitRoom(String roomId) {
    return _run(roomId, () => _repository.submitRoom(roomId));
  }

  Future<bool> confirmAvailability(String roomId) {
    return _run(roomId, () => _repository.confirmAvailability(roomId));
  }

  Future<bool> markRented(String roomId) {
    return _run(roomId, () => _repository.markRented(roomId));
  }

  Future<bool> unmarkRented(String roomId) {
    return _run(roomId, () => _repository.unmarkRented(roomId));
  }

  Future<bool> _run(String roomId, Future<void> Function() operation) async {
    state = const AsyncLoading();
    try {
      await operation();
      state = const AsyncData(null);
      ref.invalidate(landlordRoomsProvider);
      ref.invalidate(landlordRoomDetailProvider(roomId));
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
