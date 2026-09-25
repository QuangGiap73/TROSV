import '../entities/room_detail.dart';
import '../entities/room_summary.dart';

abstract interface class RoomRepository {
  Future<List<RoomSummary>> getFeaturedRooms({int limit = 5});
  Future<RoomDetail> getRoomDetail(String roomId);
  Future<List<RoomSummary>> getFavorites({int page = 1, int limit = 20});
  Future<void> addFavorite(String roomId);
  Future<void> removeFavorite(String roomId);
}
