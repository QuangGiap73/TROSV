import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/entities/create_room_reference.dart';
import '../../../domain/entities/landlord_room_detail.dart';

enum RoomFormMode { create, edit }

class ExistingRoomMedia {
  const ExistingRoomMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    required this.isPrimary,
  });

  final String id;
  final String mediaType;
  final String url;
  final bool isPrimary;
}

class RoomSpaceDraft {
  RoomSpaceDraft({
    required this.type,
    required this.title,
    this.privacyType = 'PRIVATE',
    this.description = '',
    this.id,
    this.originalKey,
  });

  final String type;
  final String title;
  String privacyType;
  String description;
  String? id;
  String? originalKey;
}

class CreateRoomDraft extends ChangeNotifier {
  CreateRoomDraft({this.mode = RoomFormMode.create});

  factory CreateRoomDraft.fromDetail(LandlordRoomDetail detail) {
    final draft = CreateRoomDraft(mode: RoomFormMode.edit)
      ..roomId = detail.id
      ..roomPropertyId = detail.propertyId
      ..propertyId = detail.propertyId
      ..propertyName = detail.property?.name ?? detail.propertyName ?? ''
      ..addressText = detail.property?.addressText ?? detail.addressText ?? ''
      ..province = detail.property?.province ?? detail.province ?? ''
      ..district = detail.property?.district ?? detail.district ?? ''
      ..ward = detail.property?.ward ?? ''
      ..latitude = detail.property?.latitude
      ..longitude = detail.property?.longitude
      ..title = detail.title
      ..roomType = detail.roomType
      ..areaM2 = detail.areaM2
      ..floor = detail.floor
      ..maxPeople = detail.maxPeople
      ..priceMonthly = detail.priceMonthly
      ..depositAmount = detail.depositAmount
      ..availableDate = detail.availableDate ?? DateTime.now()
      ..description = detail.description ?? ''
      ..houseRules = detail.houseRules ?? '';

    final cost = detail.cost;
    if (cost != null) {
      draft
        ..electricityType = cost.electricityType ?? 'PER_KWH'
        ..electricityPrice = cost.electricityPrice
        ..waterType = cost.waterType ?? 'PER_M3'
        ..waterPrice = cost.waterPrice
        ..internetFee = cost.internetFee
        ..parkingFee = cost.parkingFee
        ..serviceFee = cost.serviceFee
        ..cleaningFee = cost.cleaningFee
        ..otherFee = cost.otherFee
        ..otherDescription = cost.otherDescription ?? '';
    }

    draft.amenityCodes.addAll(detail.amenities.map((item) => item.code));
    draft.spaces
      ..clear()
      ..addAll(
        detail.spaces.map((item) {
          final title = _spaceTitle(item.spaceType);
          final key =
              '${item.spaceType}|${item.privacyType}|${(item.description ?? '').trim()}';
          return RoomSpaceDraft(
            id: item.id,
            type: item.spaceType,
            title: title,
            privacyType: item.privacyType,
            description: item.description ?? '',
            originalKey: key,
          );
        }),
      );
    draft.existingMedia.addAll(
      detail.media
          .where((item) => item.displayUrl != null)
          .map(
            (item) => ExistingRoomMedia(
              id: item.id,
              mediaType: item.mediaType,
              url: item.displayUrl!,
              isPrimary: item.isPrimary,
            ),
          ),
    );
    return draft;
  }

  final RoomFormMode mode;
  bool get isEditing => mode == RoomFormMode.edit;
  String? roomId;
  String? roomPropertyId;
  Map<String, dynamic>? backendPreview;
  final Set<String> confirmedMediaPaths = {};
  final Set<String> syncedSpaceKeys = {};
  final Set<String> removedMediaIds = {};
  final Set<String> removedSpaceIds = {};

  // Bước 1: khu trọ
  String? propertyId;
  String propertyName = '';
  String addressText = '';
  String province = 'Hà Nội';
  String district = '';
  String ward = '';
  double? latitude;
  double? longitude;

  // Bước 2: thông tin phòng
  String title = '';
  String roomType = 'ROOM_SINGLE';
  double? areaM2;
  int? floor;
  int maxPeople = 1;
  int? priceMonthly;
  int depositAmount = 0;
  DateTime availableDate = DateTime.now();

  // Bước 3: media và không gian
  final List<XFile> images = [];
  final List<XFile> videos = [];
  final List<ExistingRoomMedia> existingMedia = [];
  final List<RoomSpaceDraft> spaces = [
    RoomSpaceDraft(
      type: 'MAIN_ROOM',
      title: 'Phòng chính',
      description: 'Diện tích rộng, có cửa sổ',
    ),
    RoomSpaceDraft(
      type: 'BATHROOM',
      title: 'Nhà vệ sinh',
      description: 'WC khép kín, sạch sẽ',
    ),
  ];

  // Bước 4: chi phí
  String electricityType = 'PER_KWH';
  int electricityPrice = 0;
  String waterType = 'PER_M3';
  int waterPrice = 0;
  int internetFee = 0;
  int parkingFee = 0;
  int serviceFee = 0;
  int cleaningFee = 0;
  int otherFee = 0;
  String otherDescription = '';

  // Tiện ích lấy code từ GET /api/v1/amenities
  final Set<String> amenityCodes = {};

  // Bước 5
  String description = '';
  String houseRules = '';

  void changed() {
    notifyListeners();
  }

  void selectProperty(LandlordProperty? property) {
    propertyId = property?.id;
    if (property == null) {
      propertyName = '';
      addressText = '';
      province = 'Hà Nội';
      district = '';
      ward = '';
      latitude = null;
      longitude = null;
    } else {
      propertyName = property.name;
      addressText = property.addressText;
      province = property.province;
      district = property.district;
      ward = property.ward;
      latitude = property.latitude;
      longitude = property.longitude;
    }
    notifyListeners();
  }

  void toggleAmenity(String code) {
    if (!amenityCodes.add(code)) {
      amenityCodes.remove(code);
    }
    notifyListeners();
  }

  void addImages(List<XFile> files) {
    images.addAll(files);

    // Giới hạn tối đa 10 ảnh.
    final availableSlots = (10 - existingImages.length).clamp(0, 10);
    if (images.length > availableSlots) {
      images.removeRange(availableSlots, images.length);
    }

    notifyListeners();
  }

  void removeImage(int index) {
    images.removeAt(index);
    notifyListeners();
  }

  void removeExistingMedia(ExistingRoomMedia media) {
    existingMedia.remove(media);
    removedMediaIds.add(media.id);
    notifyListeners();
  }

  void addVideo(XFile file) {
    final oldVideos = existingVideos;
    removedMediaIds.addAll(oldVideos.map((item) => item.id));
    existingMedia.removeWhere(
      (item) => item.mediaType.toUpperCase() == 'VIDEO',
    );
    videos
      ..clear()
      ..add(file);

    notifyListeners();
  }

  void addSpace(RoomSpaceDraft space) {
    spaces.add(space);
    notifyListeners();
  }

  void removeSpace(int index) {
    final space = spaces.removeAt(index);
    if (space.id != null) removedSpaceIds.add(space.id!);
    notifyListeners();
  }

  bool get isPropertyValid =>
      (isEditing && propertyId?.isNotEmpty == true) ||
      (propertyName.trim().isNotEmpty &&
          addressText.trim().isNotEmpty &&
          province.trim().isNotEmpty &&
          ward.trim().isNotEmpty &&
          latitude != null &&
          longitude != null);

  bool get isRoomInformationValid =>
      title.trim().length >= 5 &&
      areaM2 != null &&
      areaM2! > 0 &&
      priceMonthly != null &&
      priceMonthly! > 0;

  bool get hasMedia =>
      images.isNotEmpty ||
      existingMedia.any((item) => item.mediaType.toUpperCase() == 'IMAGE');

  List<ExistingRoomMedia> get existingImages => existingMedia
      .where((item) => item.mediaType.toUpperCase() == 'IMAGE')
      .toList(growable: false);

  List<ExistingRoomMedia> get existingVideos => existingMedia
      .where((item) => item.mediaType.toUpperCase() == 'VIDEO')
      .toList(growable: false);

  String spaceKey(RoomSpaceDraft space) =>
      '${space.type}|${space.privacyType}|${space.description.trim()}';

  @override
  void dispose() {
    for (final image in images) {
      // XFile không cần dispose.
      image.path;
    }
    super.dispose();
  }
}

String _spaceTitle(String type) => switch (type) {
  'MAIN_ROOM' => 'Phòng chính',
  'BATHROOM' => 'Nhà vệ sinh',
  'KITCHEN' => 'Khu bếp',
  'BALCONY' => 'Ban công',
  _ => 'Không gian khác',
};
