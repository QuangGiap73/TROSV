import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/entities/create_room_reference.dart';

class RoomSpaceDraft {
  RoomSpaceDraft({
    required this.type,
    required this.title,
    this.privacyType = 'PRIVATE',
    this.description = '',
  });

  final String type;
  final String title;
  String privacyType;
  String description;
}

class CreateRoomDraft extends ChangeNotifier {
  String? roomId;
  String? roomPropertyId;
  Map<String, dynamic>? backendPreview;
  final Set<String> confirmedMediaPaths = {};
  final Set<String> syncedSpaceKeys = {};

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
    if (images.length > 10) {
      images.removeRange(10, images.length);
    }

    notifyListeners();
  }

  void removeImage(int index) {
    images.removeAt(index);
    notifyListeners();
  }

  void addVideo(XFile file) {
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
    spaces.removeAt(index);
    notifyListeners();
  }

  bool get isPropertyValid =>
      propertyName.trim().isNotEmpty &&
      addressText.trim().isNotEmpty &&
      province.trim().isNotEmpty &&
      ward.trim().isNotEmpty &&
      latitude != null &&
      longitude != null;

  bool get isRoomInformationValid =>
      title.trim().length >= 5 &&
      areaM2 != null &&
      areaM2! > 0 &&
      priceMonthly != null &&
      priceMonthly! > 0;

  bool get hasMedia => images.isNotEmpty;

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
