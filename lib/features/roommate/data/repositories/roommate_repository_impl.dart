import 'package:dio/dio.dart';

import '../../domain/entities/roommate_post.dart';
import '../../domain/entities/roommate_contact.dart';
import '../../domain/models/create_roommate_post_request.dart';
import '../../domain/repositories/roommate_repository.dart';
import '../datasources/roommate_remote_data_source.dart';

class RoommateRepositoryImpl implements RoommateRepository {
  const RoommateRepositoryImpl(this._remote);

  final RoommateRemoteDataSource _remote;

  @override
  Future<List<RoommatePost>> getPosts({
    String? district,
    int? minBudget,
    int? maxBudget,
    String? gender,
    String? postType,
    String? universityOrWork,
    int page = 1,
    int limit = 12,
  }) {
    return _execute(
      () => _remote.getPosts(
        district: district,
        minBudget: minBudget,
        maxBudget: maxBudget,
        gender: gender,
        postType: postType,
        universityOrWork: universityOrWork,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<List<RoommatePost>> getMyPosts() {
    return _execute(_remote.getMyPosts);
  }

  @override
  Future<RoommatePost> getPostDetail(String postId) {
    return _execute(() => _remote.getPostDetail(postId));
  }

  @override
  Future<RoommateContact> getContact(String postId) {
    return _execute(() => _remote.getContact(postId));
  }

  @override
  Future<RoommatePost> createPost(CreateRoommatePostRequest request) {
    return _execute(() => _remote.createPost(request.toJson()));
  }

  @override
  Future<RoommatePost> updateMemberCounts({
    required String postId,
    required int currentMembers,
    required int desiredRoommates,
  }) {
    return _execute(
      () => _remote.updatePost(postId, {
        'current_members': currentMembers,
        'desired_roommates': desiredRoommates,
      }),
    );
  }

  @override
  Future<RoommatePost> closePost(String postId) {
    return _execute(() => _remote.closePost(postId));
  }

  @override
  Future<void> deletePost(String postId) {
    return _execute(() => _remote.deletePost(postId));
  }

  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw RoommateFailure(_dioMessage(error));
    } on FormatException catch (error) {
      throw RoommateFailure(error.message);
    } on TypeError {
      throw const RoommateFailure(
        'Dữ liệu bài ở ghép từ máy chủ không hợp lệ.',
      );
    }
  }
}

String _dioMessage(DioException error) {
  final body = error.response?.data;

  if (body is Map<String, dynamic>) {
    final apiError = body['error'];

    if (apiError is Map<String, dynamic> && apiError['message'] is String) {
      return apiError['message'] as String;
    }

    if (body['message'] is String) {
      return body['message'] as String;
    }

    final detail = body['detail'];

    if (detail is List &&
        detail.isNotEmpty &&
        detail.first is Map &&
        (detail.first as Map)['msg'] is String) {
      return (detail.first as Map)['msg'] as String;
    }
  }

  return switch (error.response?.statusCode) {
    400 => 'Thông tin bài đăng chưa hợp lệ.',
    401 => 'Bạn cần đăng nhập lại.',
    403 => 'Bạn không có quyền thực hiện thao tác này.',
    404 => 'Không tìm thấy bài đăng.',
    409 => 'Bài đăng đã tồn tại hoặc bị trùng.',
    422 => 'Vui lòng kiểm tra lại các trường đã nhập.',
    _ => 'Không thể kết nối dịch vụ ở ghép.',
  };
}
