import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/network/dio_provider.dart';
import '../../../data/datasources/create_room_remote_data_source.dart';
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
  CreateRoomRemoteDataSource get _api =>
      ref.read(createRoomRemoteDataSourceProvider);

  @override
  Future<String?> build() async => null;

  Future<bool> ensureDraftRoom(CreateRoomDraft draft) async {
    final result = await _execute(() async {
      final propertyId = await _ensureProperty(draft);
      final payload = _roomPayload(draft);
      if (draft.roomId == null) {
        draft.roomId = await _api.createRoom({
          'property_id': propertyId,
          ...payload,
        });
        draft.roomPropertyId = propertyId;
      } else {
        if (draft.roomPropertyId != propertyId) {
          throw const FormatException(
            'Không thể đổi khu trọ sau khi đã tạo phòng nháp. '
            'Hãy thoát và tạo lại phòng nếu muốn đổi khu trọ.',
          );
        }
        await _api.updateRoom(draft.roomId!, payload);
      }
      return true;
    });
    return result ?? false;
  }

  Future<bool> syncMediaAndSpaces(CreateRoomDraft draft) async {
    final result = await _execute(() async {
      final roomId = _requiredRoomId(draft);

      for (final mediaId in draft.removedMediaIds.toList()) {
        await _api.deleteMedia(mediaId);
        draft.removedMediaIds.remove(mediaId);
      }

      final files = <XFile>[...draft.images, ...draft.videos];

      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        if (draft.confirmedMediaPaths.contains(file.path)) continue;
        final contentType = _contentType(file);
        final presigned = await _api.presignMedia(
          roomId: roomId,
          file: file,
          contentType: contentType,
        );
        await _api.uploadToPresignedUrl(
          presigned: presigned,
          file: file,
          contentType: contentType,
        );
        await _api.confirmMedia(
          roomId: roomId,
          objectKey: presigned.objectKey,
          isPrimary: draft.existingImages.isEmpty && index == 0,
          sortOrder: draft.existingMedia.length + index,
        );
        draft.confirmedMediaPaths.add(file.path);
      }

      for (final spaceId in draft.removedSpaceIds.toList()) {
        await _api.deleteSpace(roomId, spaceId);
        draft.removedSpaceIds.remove(spaceId);
      }

      for (final space in draft.spaces) {
        final key = draft.spaceKey(space);
        if (space.id != null && key == space.originalKey) continue;
        if (space.id != null) {
          await _api.deleteSpace(roomId, space.id!);
          space.id = null;
        }
        if (draft.syncedSpaceKeys.contains(key)) continue;
        space.id = await _api.addSpace(roomId, {
          'space_type': space.type,
          'privacy_type': space.privacyType,
          'description': _nullIfEmpty(space.description),
        });
        space.originalKey = key;
        draft.syncedSpaceKeys.add(key);
      }
      return true;
    });
    return result ?? false;
  }

  Future<bool> saveCostsAndAmenities(CreateRoomDraft draft) async {
    final result = await _execute(() async {
      final roomId = _requiredRoomId(draft);
      await _api.upsertCosts(roomId, {
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
      await _api.setAmenities(roomId, draft.amenityCodes.toList());
      return true;
    });
    return result ?? false;
  }

  Future<bool> refreshPreview(CreateRoomDraft draft) async {
    final result = await _execute(() async {
      draft.backendPreview = await _api.getRoomDetail(_requiredRoomId(draft));
      draft.changed();
      return true;
    });
    return result ?? false;
  }

  Future<bool> finish(CreateRoomDraft draft, {required bool submit}) async {
    final result = await _execute(() async {
      final roomId = _requiredRoomId(draft);
      await _api.updateRoom(roomId, {
        ..._roomPayload(draft),
        'description': _nullIfEmpty(draft.description),
        'house_rules': _nullIfEmpty(draft.houseRules),
      });

      // Luôn GET lại dữ liệu backend trước khi cho submit.
      draft.backendPreview = await _api.getRoomDetail(roomId);
      if (submit) await _api.submitRoom(roomId);

      ref.invalidate(landlordRoomsProvider);
      ref.invalidate(landlordRoomDetailProvider(roomId));
      return true;
    });
    return result ?? false;
  }

  Future<T?> _execute<T>(Future<T> Function() operation) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final result = await operation();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(_friendlyError(error), stackTrace);
      return null;
    }
  }

  Future<String> _ensureProperty(CreateRoomDraft draft) async {
    final currentId = draft.propertyId;
    if (currentId != null && currentId.isNotEmpty) return currentId;
    final property = await _api.createProperty({
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

Map<String, dynamic> _roomPayload(CreateRoomDraft draft) => {
  'title': draft.title.trim(),
  'room_type': draft.roomType,
  'area_m2': draft.areaM2,
  'floor': draft.floor,
  'max_people': draft.maxPeople,
  'price_monthly': draft.priceMonthly,
  'deposit_amount': draft.depositAmount,
  'available_date': _date(draft.availableDate),
};

String _requiredRoomId(CreateRoomDraft draft) {
  final roomId = draft.roomId;
  if (roomId == null || roomId.isEmpty) {
    throw const FormatException(
      'Phòng nháp chưa được tạo. Hãy quay lại bước 2.',
    );
  }
  return roomId;
}

String _contentType(XFile file) {
  final detected = file.mimeType?.toLowerCase();
  if (detected != null &&
      (detected.startsWith('image/') || detected.startsWith('video/'))) {
    return detected;
  }
  final name = file.name.toLowerCase();
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.heic')) return 'image/heic';
  if (name.endsWith('.mov')) return 'video/quicktime';
  if (name.endsWith('.webm')) return 'video/webm';
  if (name.endsWith('.mp4')) return 'video/mp4';
  return 'image/jpeg';
}

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

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
  return Exception('Không thể lưu dữ liệu phòng. Vui lòng thử lại.');
}
