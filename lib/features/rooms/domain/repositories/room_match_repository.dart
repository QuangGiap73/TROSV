import '../../../preferences/domain/entities/tenant_preference.dart';
import '../entities/room_match.dart';

abstract interface class RoomMatchRepository {
  Future<List<RoomMatch>> matchRooms(
    TenantPreference preference, {
    int limit = 10,
  });
}

class RoomMatchFailure implements Exception {
  const RoomMatchFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
