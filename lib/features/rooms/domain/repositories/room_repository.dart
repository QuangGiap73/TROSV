import '../entities/room_detail.dart';
import '../entities/room_summary.dart';
import '../entities/room_search_query.dart';
import '../entities/room_report.dart';
import '../entities/room_trust.dart';

abstract interface class RoomRepository {
  Future<List<RoomSummary>> getFeaturedRooms({int limit = 5});
  Future<List<RoomSummary>> searchRooms(RoomSearchQuery query);
  Future<RoomDetail> getRoomDetail(String roomId);
  Future<List<RoomSummary>> getFavorites({int page = 1, int limit = 20});
  Future<void> addFavorite(String roomId);
  Future<void> removeFavorite(String roomId);
  Future<RoomReport> reportRoom(String roomId, RoomReportRequest request);
  Future<RoomTrust> getRoomTrust(String roomId);
}
