import 'package:dio/dio.dart';

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
}

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
