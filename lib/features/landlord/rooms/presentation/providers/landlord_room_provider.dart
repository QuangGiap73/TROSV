import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/landlord_room_remote_data_source.dart';
import '../../data/repositories/landlord_room_repository_impl.dart';
import '../../domain/entities/landlord_room.dart';
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
    return _run(() => _repository.deleteRoom(roomId));
  }

  Future<bool> updateVisibility(String roomId, {required bool visible}) {
    return _run(() => _repository.updateVisibility(roomId, visible: visible));
  }

  Future<bool> submitRoom(String roomId) {
    return _run(() => _repository.submitRoom(roomId));
  }

  Future<bool> confirmAvailability(String roomId) {
    return _run(() => _repository.confirmAvailability(roomId));
  }

  Future<bool> markRented(String roomId) {
    return _run(() => _repository.markRented(roomId));
  }

  Future<bool> unmarkRented(String roomId) {
    return _run(() => _repository.unmarkRented(roomId));
  }

  Future<bool> _run(Future<void> Function() operation) async {
    state = const AsyncLoading();
    try {
      await operation();
      state = const AsyncData(null);
      ref.invalidate(landlordRoomsProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
