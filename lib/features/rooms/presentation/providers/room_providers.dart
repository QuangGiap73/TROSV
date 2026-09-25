import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/room_remote_data_source.dart';
import '../../data/repositories/room_repository_impl.dart';
import '../../domain/entities/room_detail.dart';
import '../../domain/entities/room_summary.dart';
import '../../domain/repositories/room_repository.dart';

final roomRemoteDataSourceProvider = Provider<RoomRemoteDataSource>((ref) {
  return RoomRemoteDataSource(ref.watch(dioProvider));
});

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepositoryImpl(ref.watch(roomRemoteDataSourceProvider));
});

final featuredRoomsProvider = FutureProvider<List<RoomSummary>>((ref) {
  return ref.watch(roomRepositoryProvider).getFeaturedRooms();
});

final roomDetailProvider = FutureProvider.family<RoomDetail, String>((ref, id) {
  return ref.watch(roomRepositoryProvider).getRoomDetail(id);
});
