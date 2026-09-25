import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../rooms/domain/entities/room_summary.dart';
import '../../../rooms/presentation/providers/room_providers.dart';

final favoritesProvider =
    AsyncNotifierProvider<FavoritesController, List<RoomSummary>>(
      FavoritesController.new,
    );

class FavoritesController extends AsyncNotifier<List<RoomSummary>> {
  @override
  Future<List<RoomSummary>> build() async {
    final authState = ref.watch(authControllerProvider);
    final session = authState.asData?.value;
    if (session == null) return const [];
    return ref.read(roomRepositoryProvider).getFavorites();
  }

  bool isFavorite(String roomId) {
    return state.asData?.value.any((room) => room.id == roomId) ?? false;
  }

  Future<void> toggle(RoomSummary room) async {
    if (isFavorite(room.id)) {
      await remove(room.id);
    } else {
      await add(room);
    }
  }

  Future<void> add(RoomSummary room) async {
    final previous = state.asData?.value ?? const <RoomSummary>[];
    if (previous.any((item) => item.id == room.id)) return;
    state = AsyncData([room, ...previous]);
    try {
      await ref.read(roomRepositoryProvider).addFavorite(room.id);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> remove(String roomId) async {
    final previous = state.asData?.value ?? const <RoomSummary>[];
    state = AsyncData(previous.where((room) => room.id != roomId).toList());
    try {
      await ref.read(roomRepositoryProvider).removeFavorite(roomId);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}
