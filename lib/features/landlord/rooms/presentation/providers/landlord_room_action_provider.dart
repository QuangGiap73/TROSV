import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'landlord_room_provider.dart';

typedef LandlordRoomActionState = Map<String, AsyncValue<void>>;

// Quản lý trạng thái action theo từng roomId.
///
/// Điểm khác với `AsyncNotifier<void>` dùng chung trước đây:
/// khi thao tác phòng A thì chỉ A ở trạng thái loading; phòng B/C không bị khóa.
final landlordRoomActionProvider =
    NotifierProvider<LandlordRoomActionController, LandlordRoomActionState>(
      LandlordRoomActionController.new,
    );

final landlordRoomActionLoadingProvider = Provider.family<bool, String>((
  ref,
  roomId,
) {
  return ref.watch(
    landlordRoomActionProvider.select(
      (state) => state[roomId]?.isLoading ?? false,
    ),
  );
});

final landlordAnyRoomActionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(
    landlordRoomActionProvider.select(
      (state) => state.values.any((value) => value.isLoading),
    ),
  );
});

final landlordRoomActionErrorProvider = Provider.family<Object?, String>((
  ref,
  roomId,
) {
  return ref.watch(
    landlordRoomActionProvider.select((state) => state[roomId]?.error),
  );
});

class LandlordRoomActionController extends Notifier<LandlordRoomActionState> {
  @override
  LandlordRoomActionState build() => const {};

  Future<bool> deleteRoom(String roomId) {
    return _run(
      roomId,
      () => ref.read(landlordRoomRepositoryProvider).deleteRoom(roomId),
    );
  }

  Future<bool> updateVisibility(String roomId, {required bool visible}) {
    return _run(
      roomId,
      () => ref
          .read(landlordRoomRepositoryProvider)
          .updateVisibility(roomId, visible: visible),
    );
  }

  Future<bool> submitRoom(String roomId) {
    return _run(
      roomId,
      () => ref.read(landlordRoomRepositoryProvider).submitRoom(roomId),
    );
  }

  Future<bool> confirmAvailability(String roomId) {
    return _run(
      roomId,
      () =>
          ref.read(landlordRoomRepositoryProvider).confirmAvailability(roomId),
    );
  }

  Future<bool> markRented(String roomId) {
    return _run(
      roomId,
      () => ref.read(landlordRoomRepositoryProvider).markRented(roomId),
    );
  }

  Future<bool> unmarkRented(String roomId) {
    return _run(
      roomId,
      () => ref.read(landlordRoomRepositoryProvider).unmarkRented(roomId),
    );
  }

  void clearError(String roomId) {
    if (!state.containsKey(roomId)) return;
    final next = Map<String, AsyncValue<void>>.from(state);
    next.remove(roomId);
    state = next;
  }

  Future<bool> _run(String roomId, Future<void> Function() operation) async {
    // Chống double tap / gửi request trùng.
    if (state[roomId]?.isLoading == true) return false;

    state = {...state, roomId: const AsyncLoading()};

    try {
      await operation();

      // Cập nhật lại cả list và detail sau action.
      // UI dùng skipLoadingOnRefresh nên vẫn giữ data cũ trong lúc refresh.
      ref.invalidate(landlordRoomsProvider);
      ref.invalidate(landlordRoomDetailProvider(roomId));

      // Không giữ các action thành công trong Map để state không tăng mãi
      // khi chủ trọ thao tác trên nhiều phòng.
      final next = Map<String, AsyncValue<void>>.from(state);
      next.remove(roomId);
      state = next;

      return true;
    } catch (error, stackTrace) {
      state = {...state, roomId: AsyncError<void>(error, stackTrace)};
      return false;
    }
  }
}
