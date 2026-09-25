import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/landlord_room_remote_data_source.dart';
import '../../data/repositories/landlord_room_repository.dart';
import '../../domain/entities/landlord_room.dart';

final landlordRoomRemoteDataSourceProvider = Provider(
  (ref) => LandlordRoomRemoteDataSource(ref.watch(dioProvider)),
);

final landlordRoomRepositoryProvider = Provider(
  (ref) =>
      LandlordRoomRepository(ref.watch(landlordRoomRemoteDataSourceProvider)),
);

final landlordRoomsProvider =
    FutureProvider.family<List<LandlordRoom>, String?>(
      (ref, status) =>
          ref.watch(landlordRoomRepositoryProvider).getRooms(status: status),
    );
