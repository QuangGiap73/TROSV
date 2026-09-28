import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/create_room_reference.dart';

class CreateRoomRemoteDataSource {
  const CreateRoomRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<LandlordProperty>> getProperties() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/landlord/properties',
    );
    return _listData(response).map(LandlordProperty.fromJson).toList();
  }

  Future<List<AmenityOption>> getAmenities() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/amenities');
    return _listData(response).map(AmenityOption.fromJson).toList();
  }

  Future<LandlordProperty> createProperty(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/landlord/properties',
      data: payload,
    );
    return LandlordProperty.fromJson(_mapData(response));
  }

  Future<UploadedRoomMedia> uploadMedia(XFile file) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/media/upload',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      }),
    );
    return UploadedRoomMedia.fromJson(_mapData(response));
  }

  Future<String> createRoom(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/landlord/rooms',
      data: payload,
    );
    final id = _mapData(response)['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Máy chủ không trả về mã phòng.');
    }
    return id;
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> payload) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId',
      data: payload,
    );
  }

  Future<Map<String, dynamic>> getRoomDetail(String roomId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/landlord/rooms/$roomId',
    );
    return _mapData(response);
  }

  Future<PresignedMediaUpload> presignMedia({
    required String roomId,
    required XFile file,
    required String contentType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/media/presign',
      data: {
        'room_id': roomId,
        'filename': file.name,
        'content_type': contentType,
        'file_size': await file.length(),
      },
    );
    return PresignedMediaUpload.fromJson(_mapData(response));
  }

  Future<void> uploadToPresignedUrl({
    required PresignedMediaUpload presigned,
    required XFile file,
    required String contentType,
  }) async {
    final storageDio = Dio();
    try {
      await storageDio.put<void>(
        presigned.uploadUrl,
        data: file.openRead(),
        options: Options(
          contentType: contentType,
          headers: {'Content-Length': await file.length()},
        ),
      );
    } finally {
      storageDio.close();
    }
  }

  Future<void> confirmMedia({
    required String roomId,
    required String objectKey,
    required bool isPrimary,
    required int sortOrder,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/media/confirm',
      data: {
        'room_id': roomId,
        'object_key': objectKey,
        'is_primary': isPrimary,
        'sort_order': sortOrder,
      },
    );
  }

  Future<void> addSpace(String roomId, Map<String, dynamic> payload) =>
      _dio.post<Map<String, dynamic>>(
        '/api/v1/landlord/rooms/$roomId/spaces',
        data: payload,
      );
  Future<void> upsertCosts(String roomId, Map<String, dynamic> payload) =>
      _dio.put<Map<String, dynamic>>(
        '/api/v1/landlord/rooms/$roomId/costs',
        data: payload,
      );
  Future<void> setAmenities(String roomId, List<String> codes) =>
      _dio.put<Map<String, dynamic>>(
        '/api/v1/landlord/rooms/$roomId/amenities',
        data: {'amenity_codes': codes},
      );
  Future<void> submitRoom(String roomId) =>
      _dio.post<Map<String, dynamic>>('/api/v1/landlord/rooms/$roomId/submit');
}

List<Map<String, dynamic>> _listData(Response<Map<String, dynamic>> response) {
  final envelope = response.data;
  final data = envelope?['data'];
  if (envelope?['success'] != true || data is! List) {
    throw const FormatException('Dữ liệu danh sách không hợp lệ.');
  }
  return data.whereType<Map<String, dynamic>>().toList(growable: false);
}

Map<String, dynamic> _mapData(Response<Map<String, dynamic>> response) {
  final envelope = response.data;
  final data = envelope?['data'];
  if (envelope?['success'] != true || data is! Map<String, dynamic>) {
    throw const FormatException('Dữ liệu máy chủ trả về không hợp lệ.');
  }
  return data;
}
