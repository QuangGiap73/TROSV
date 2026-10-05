import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/room_report.dart';
import 'room_providers.dart';

final roomReportControllerProvider =
    AsyncNotifierProvider<RoomReportController, RoomReport?>(
      RoomReportController.new,
    );

class RoomReportController extends AsyncNotifier<RoomReport?> {
  @override
  Future<RoomReport?> build() async => null;

  void clear() => state = const AsyncData(null);

  Future<RoomReport?> submit({
    required String roomId,
    required RoomReportType type,
    String? description,
  }) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final report = await ref
          .read(roomRepositoryProvider)
          .reportRoom(
            roomId,
            RoomReportRequest(type: type, description: description),
          );
      state = AsyncData(report);
      return report;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
