import '../entities/landlord_room.dart';
import '../entities/landlord_room_detail.dart';

abstract interface class LandlordRoomRepository {
  Future<List<LandlordRoom>> getRooms({String? status, String? propertyId});

  Future<LandlordRoomDetail> getRoomDetail(String roomId);

  Future<void> deleteRoom(String roomId);

  Future<void> updateVisibility(String roomId, {required bool visible});

  Future<void> submitRoom(String roomId);

  Future<void> confirmAvailability(String roomId);

  Future<void> markRented(String roomId);

  Future<void> unmarkRented(String roomId);
}

class LandlordRoomFailure implements Exception {
  const LandlordRoomFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
