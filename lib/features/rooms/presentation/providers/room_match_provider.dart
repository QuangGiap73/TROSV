import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../preferences/presentation/providers/preference_provider.dart';
import '../../data/datasources/room_match_remote_data_source.dart';
import '../../data/repositories/room_match_repository_impl.dart';
import '../../domain/entities/room_match.dart';
import '../../domain/repositories/room_match_repository.dart';

final roomMatchRemoteDataSourceProvider = Provider<RoomMatchRemoteDataSource>((
  ref,
) {
  return RoomMatchRemoteDataSource(ref.watch(dioProvider));
});

final roomMatchRepositoryProvider = Provider<RoomMatchRepository>((ref) {
  return RoomMatchRepositoryImpl(ref.watch(roomMatchRemoteDataSourceProvider));
});

final roomMatchesProvider =
    AsyncNotifierProvider<RoomMatchesController, List<RoomMatch>>(
      RoomMatchesController.new,
    );

class RoomMatchesController extends AsyncNotifier<List<RoomMatch>> {
  RoomMatchRepository get _repository => ref.read(roomMatchRepositoryProvider);

  @override
  Future<List<RoomMatch>> build() async {
    final preference = await ref.watch(tenantPreferenceProvider.future);

    if (preference == null) {
      throw const RoomMatchFailure('Bạn chưa thiết lập nhu cầu tìm phòng.');
    }

    return _repository.matchRooms(preference, limit: 20);
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}
