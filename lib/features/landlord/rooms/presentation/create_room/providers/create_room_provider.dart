import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/network/dio_provider.dart';
import '../../../data/datasources/create_room_remote_data_source.dart';
import '../../../domain/entities/create_room_reference.dart';
import '../../providers/landlord_room_provider.dart';
import '../models/create_room_draft.dart';

final createRoomRemoteDataSourceProvider = Provider<CreateRoomRemoteDataSource>(
  (ref) => CreateRoomRemoteDataSource(ref.watch(dioProvider)),
);
final landlordPropertiesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(createRoomRemoteDataSourceProvider).getProperties(),
);
final roomAmenitiesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(createRoomRemoteDataSourceProvider).getAmenities(),
);
final createRoomControllerProvider =
    AsyncNotifierProvider<CreateRoomController, String?>(
      CreateRoomController.new,
    );

class CreateRoomController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> save(CreateRoomDraft draft, {required bool submit}) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final api = ref.read(createRoomRemoteDataSourceProvider);
      final propertyId = await _ensureProperty(api, draft);
      final uploaded = <UploadedRoomMedia>[];
      for (final image in draft.images) {
        uploaded.add(await api.uploadMedia(image));
      }
      for (final video in draft.videos) {
        uploaded.add(await api.uploadMedia(video));
      }

      final roomId = await api.createRoom({
        'property_id': propertyId,
        'title': draft.title.trim(),
        'room_type': draft.roomType,
        'area_m2': draft.areaM2,
        'floor': draft.floor,
        'max_people': draft.maxPeople,
        'price_monthly': draft.priceMonthly,
        'deposit_amount': draft.depositAmount,
        'available_date': _date(draft.availableDate),
        'description': _nullIfEmpty(draft.description),
        'house_rules': _nullIfEmpty(draft.houseRules),
        'images': [
          for (var index = 0; index < uploaded.length; index++)
            uploaded[index].toRoomImageJson(isPrimary: index == 0),
        ],
      });

      for (final space in draft.spaces) {
        await api.addSpace(roomId, {
          'space_type': space.type,
          'description': _nullIfEmpty(space.description),
        });
      }
      await api.upsertCosts(roomId, {
        'electricity_type': draft.electricityType,
        'electricity_price': draft.electricityPrice,
        'water_type': draft.waterType,
        'water_price': draft.waterPrice,
        'internet_fee': draft.internetFee,
        'parking_fee': draft.parkingFee,
        'service_fee': draft.serviceFee,
        'cleaning_fee': draft.cleaningFee,
        'other_fee': draft.otherFee,
        'other_description': _nullIfEmpty(draft.otherDescription),
      });
      await api.setAmenities(roomId, draft.amenityCodes.toList());
      if (submit) await api.submitRoom(roomId);
      ref.invalidate(landlordRoomsProvider);
      state = AsyncData(roomId);
      return roomId;
    } catch (error, stackTrace) {
      final failure = _friendlyError(error);
      state = AsyncError(failure, stackTrace);
      return null;
    }
  }

  Future<String> _ensureProperty(
    CreateRoomRemoteDataSource api,
    CreateRoomDraft draft,
  ) async {
    final currentId = draft.propertyId;
    if (currentId != null && currentId.isNotEmpty) return currentId;
    final property = await api.createProperty({
      'name': draft.propertyName.trim(),
      'address_text': draft.addressText.trim(),
      'province': draft.province.trim(),
      'district': _nullIfEmpty(draft.district),
      'ward': draft.ward.trim(),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
    });
    draft.propertyId = property.id;
    return property.id;
  }
}

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String? _nullIfEmpty(String value) =>
    value.trim().isEmpty ? null : value.trim();

Exception _friendlyError(Object error) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      final apiError = body['error'];
      if (apiError is Map<String, dynamic> && apiError['message'] is String) {
        return Exception(apiError['message']);
      }
      if (body['message'] is String) return Exception(body['message']);
    }
    return Exception('Không thể kết nối đến máy chủ. Vui lòng thử lại.');
  }
  if (error is FormatException) return Exception(error.message);
  return Exception('Không thể đăng phòng. Vui lòng thử lại.');
}
