import '../entities/roommate_post.dart';
import '../entities/roommate_contact.dart';
import '../models/create_roommate_post_request.dart';

abstract interface class RoommateRepository {
  Future<List<RoommatePost>> getPosts({
    String? district,
    int? minBudget,
    int? maxBudget,
    String? gender,
    String? postType,
    String? universityOrWork,
    int page = 1,
    int limit = 12,
  });

  Future<List<RoommatePost>> getMyPosts();

  Future<RoommatePost> getPostDetail(String postId);

  Future<RoommateContact> getContact(String postId);

  Future<RoommatePost> createPost(CreateRoommatePostRequest request);
}

class RoommateFailure implements Exception {
  const RoommateFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
