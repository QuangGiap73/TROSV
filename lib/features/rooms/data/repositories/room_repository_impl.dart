import '../../domain/entities/room_detail.dart';
import '../../domain/entities/room_summary.dart';
import '../../domain/entities/room_search_query.dart';
import '../../domain/entities/room_report.dart';
import '../../domain/entities/room_trust.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_remote_data_source.dart';

class RoomRepositoryImpl implements RoomRepository {
  const RoomRepositoryImpl(this._remoteDataSource);
  final RoomRemoteDataSource _remoteDataSource;

  @override
  Future<List<RoomSummary>> getFeaturedRooms({int limit = 5}) =>
      _remoteDataSource.getRooms(limit: limit);

  @override
  Future<List<RoomSummary>> searchRooms(RoomSearchQuery query) =>
      _remoteDataSource.searchRooms(query);

  @override
  Future<RoomDetail> getRoomDetail(String roomId) =>
      _remoteDataSource.getRoomDetail(roomId);

  @override
  Future<void> addFavorite(String roomId) =>
      _remoteDataSource.addFavorite(roomId);

  @override
  Future<List<RoomSummary>> getFavorites({int page = 1, int limit = 20}) =>
      _remoteDataSource.getFavorites(page: page, limit: limit);

  @override
  Future<void> removeFavorite(String roomId) =>
      _remoteDataSource.removeFavorite(roomId);

  @override
  Future<RoomReport> reportRoom(String roomId, RoomReportRequest request) =>
      _remoteDataSource.reportRoom(roomId, request);

  @override
  Future<RoomTrust> getRoomTrust(String roomId) =>
      _remoteDataSource.getRoomTrust(roomId);
}
