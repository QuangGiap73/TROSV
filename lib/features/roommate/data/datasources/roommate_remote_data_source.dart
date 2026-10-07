import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/roommate_post.dart';
import '../../domain/entities/roommate_contact.dart';

class RoommateRemoteDataSource {
  const RoommateRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RoommatePost>> getPosts({
    String? district,
    int? minBudget,
    int? maxBudget,
    String? gender,
    String? postType,
    String? universityOrWork,
    int page = 1,
    int limit = 12,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/roommate-posts',
      queryParameters: {
        if (_hasText(district)) 'district': district!.trim(),
        'min_budget': ?minBudget,
        'max_budget': ?maxBudget,
        if (_hasText(gender)) 'gender': gender,
        if (_hasText(postType)) 'post_type': postType,
        if (_hasText(universityOrWork))
          'university_or_work': universityOrWork!.trim(),
        'page': page,
        'limit': limit,
      },
    );

    return _readList(response);
  }

  Future<List<RoommatePost>> getMyPosts() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/roommate-posts/mine',
    );

    return _readList(response);
  }

  Future<RoommatePost> getPostDetail(String postId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/roommate-posts/$postId',
    );
    return RoommatePost.fromJson(_readMap(response));
  }

  Future<RoommateContact> getContact(String postId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/roommate-posts/$postId/contact',
    );
    return RoommateContact.fromJson(_readMap(response));
  }

  Future<RoommatePost> createPost(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/roommate-posts',
      data: payload,
    );

    return RoommatePost.fromJson(_readMap(response));
  }

  Future<String> uploadMedia(XFile file) async {
    final media = await _detectMedia(file);
    final originalStem = file.name
        .replaceFirst(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final uploadName =
        '${originalStem.isEmpty ? 'media' : originalStem}'
        '.${media.extension}';
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/media/upload',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: uploadName,
          contentType: MediaType.parse(media.mimeType),
        ),
      }),
    );
    final data = _readMap(response);
    final url = data['public_url'] ?? data['url'];
    if (url is! String || url.trim().isEmpty) {
      throw const FormatException('Máy chủ không trả về đường dẫn ảnh/video.');
    }
    return url.trim();
  }

  Future<RoommatePost> updatePost(
    String postId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/roommate-posts/$postId',
      data: payload,
    );
    return RoommatePost.fromJson(_readMap(response));
  }

  Future<RoommatePost> closePost(String postId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/roommate-posts/$postId/close',
    );
    return RoommatePost.fromJson(_readMap(response));
  }

  Future<void> deletePost(String postId) async {
    await _dio.delete<Map<String, dynamic>>('/api/v1/roommate-posts/$postId');
  }
}

class _DetectedMedia {
  const _DetectedMedia(this.mimeType, this.extension);
  final String mimeType, extension;
}

Future<_DetectedMedia> _detectMedia(XFile file) async {
  final bytes = await file
      .openRead(0, 16)
      .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
  bool startsWith(List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) {
    return const _DetectedMedia('image/jpeg', 'jpg');
  }
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) {
    return const _DetectedMedia('image/png', 'png');
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return const _DetectedMedia('image/webp', 'webp');
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
    final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    if (brand.startsWith('hei') || brand == 'mif1') {
      return const _DetectedMedia('image/heic', 'heic');
    }
    if (brand.startsWith('qt')) {
      return const _DetectedMedia('video/quicktime', 'mov');
    }
    if (brand.startsWith('3g')) {
      return const _DetectedMedia('video/3gpp', '3gp');
    }
    return const _DetectedMedia('video/mp4', 'mp4');
  }
  if (startsWith(const [0x1A, 0x45, 0xDF, 0xA3])) {
    return const _DetectedMedia('video/webm', 'webm');
  }

  final declared = file.mimeType?.toLowerCase();
  if (declared?.startsWith('video/') == true) {
    return _DetectedMedia(declared!, _extensionForMime(declared));
  }
  if (declared?.startsWith('image/') == true) {
    return _DetectedMedia(declared!, _extensionForMime(declared));
  }
  throw const FormatException(
    'Không nhận diện được định dạng tệp. Hãy chọn ảnh JPG, PNG, WEBP hoặc video MP4.',
  );
}

String _extensionForMime(String mime) => switch (mime) {
  'image/png' => 'png',
  'image/webp' => 'webp',
  'image/heic' || 'image/heif' => 'heic',
  'video/quicktime' => 'mov',
  'video/webm' => 'webm',
  'video/3gpp' => '3gp',
  'video/mp4' => 'mp4',
  _ => 'jpg',
};

List<RoommatePost> _readList(Response<Map<String, dynamic>> response) {
  final envelope = response.data;
  final data = envelope?['data'];

  if (envelope?['success'] != true || data is! List) {
    throw const FormatException('Danh sách bài ở ghép không đúng định dạng.');
  }

  return data
      .whereType<Map<String, dynamic>>()
      .map(RoommatePost.fromJson)
      .toList(growable: false);
}

Map<String, dynamic> _readMap(Response<Map<String, dynamic>> response) {
  final envelope = response.data;
  final data = envelope?['data'];

  if (envelope?['success'] != true || data is! Map<String, dynamic>) {
    throw const FormatException('Dữ liệu bài ở ghép không đúng định dạng.');
  }

  return data;
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}
