import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/roommate_remote_data_source.dart';
import '../../data/repositories/roommate_repository_impl.dart';
import '../../domain/entities/roommate_post.dart';
import '../../domain/entities/roommate_contact.dart';
import '../../domain/models/create_roommate_post_request.dart';
import '../../domain/repositories/roommate_repository.dart';

final roommateRemoteDataSourceProvider = Provider(
  (ref) => RoommateRemoteDataSource(ref.watch(dioProvider)),
);

final roommateRepositoryProvider = Provider<RoommateRepository>(
  (ref) => RoommateRepositoryImpl(ref.watch(roommateRemoteDataSourceProvider)),
);

class RoommateFilter {
  const RoommateFilter({
    this.district,
    this.minBudget,
    this.maxBudget,
    this.gender,
    this.postType,
    this.universityOrWork,
  });

  final String? district;
  final int? minBudget;
  final int? maxBudget;
  final String? gender;
  final String? postType;
  final String? universityOrWork;

  @override
  bool operator ==(Object other) {
    return other is RoommateFilter &&
        district == other.district &&
        minBudget == other.minBudget &&
        maxBudget == other.maxBudget &&
        gender == other.gender &&
        postType == other.postType &&
        universityOrWork == other.universityOrWork;
  }

  @override
  int get hashCode => Object.hash(
    district,
    minBudget,
    maxBudget,
    gender,
    postType,
    universityOrWork,
  );
}

final roommateFilterProvider =
    NotifierProvider<RoommateFilterController, RoommateFilter>(
      RoommateFilterController.new,
    );

class RoommateFilterController extends Notifier<RoommateFilter> {
  @override
  RoommateFilter build() {
    return const RoommateFilter();
  }

  void update(RoommateFilter filter) {
    state = filter;
  }

  void clear() {
    state = const RoommateFilter();
  }
}

final roommatePostsProvider = FutureProvider.autoDispose<List<RoommatePost>>((
  ref,
) {
  final filter = ref.watch(roommateFilterProvider);

  return ref
      .watch(roommateRepositoryProvider)
      .getPosts(
        district: filter.district,
        minBudget: filter.minBudget,
        maxBudget: filter.maxBudget,
        gender: filter.gender,
        postType: filter.postType,
        universityOrWork: filter.universityOrWork,
      );
});

final myRoommatePostsProvider = FutureProvider.autoDispose<List<RoommatePost>>((
  ref,
) {
  return ref.watch(roommateRepositoryProvider).getMyPosts();
});

enum MyRoommatePostFilter { all, pending, active, rejected, closed }

final myRoommatePostFilterProvider =
    NotifierProvider<MyRoommatePostFilterController, MyRoommatePostFilter>(
      MyRoommatePostFilterController.new,
    );

class MyRoommatePostFilterController extends Notifier<MyRoommatePostFilter> {
  @override
  MyRoommatePostFilter build() => MyRoommatePostFilter.all;

  void select(MyRoommatePostFilter value) => state = value;
}

final filteredMyRoommatePostsProvider =
    Provider<AsyncValue<List<RoommatePost>>>((ref) {
      final filter = ref.watch(myRoommatePostFilterProvider);
      return ref.watch(myRoommatePostsProvider).whenData((posts) {
        return posts
            .where((post) {
              return switch (filter) {
                MyRoommatePostFilter.all => true,
                MyRoommatePostFilter.pending => post.status == 'PENDING_REVIEW',
                MyRoommatePostFilter.active => post.status == 'ACTIVE',
                MyRoommatePostFilter.rejected => post.status == 'REJECTED',
                MyRoommatePostFilter.closed => post.status == 'CLOSED',
              };
            })
            .toList(growable: false);
      });
    });

final roommatePostDetailProvider = FutureProvider.autoDispose
    .family<RoommatePost, String>((ref, postId) {
      return ref.watch(roommateRepositoryProvider).getPostDetail(postId);
    });

final roommateContactProvider = FutureProvider.autoDispose
    .family<RoommateContact, String>((ref, postId) {
      return ref.watch(roommateRepositoryProvider).getContact(postId);
    });

final roommatePostActionProvider =
    AsyncNotifierProvider<RoommatePostActionController, void>(
      RoommatePostActionController.new,
    );

class RoommatePostActionController extends AsyncNotifier<void> {
  RoommateRepository get _repository {
    return ref.read(roommateRepositoryProvider);
  }

  @override
  Future<void> build() async {}

  Future<RoommatePost?> createPost(CreateRoommatePostRequest request) async {
    if (state.isLoading) return null;

    state = const AsyncLoading();

    try {
      final post = await _repository.createPost(request);

      state = const AsyncData(null);

      ref.invalidate(roommatePostsProvider);
      ref.invalidate(myRoommatePostsProvider);

      return post;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> updateMemberCounts({
    required String postId,
    required int currentMembers,
    required int desiredRoommates,
  }) {
    return _run(
      postId,
      () => _repository.updateMemberCounts(
        postId: postId,
        currentMembers: currentMembers,
        desiredRoommates: desiredRoommates,
      ),
    );
  }

  Future<bool> closePost(String postId) {
    return _run(postId, () => _repository.closePost(postId));
  }

  Future<bool> deletePost(String postId) {
    return _run(postId, () => _repository.deletePost(postId));
  }

  Future<bool> _run(String postId, Future<Object?> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      ref.invalidate(roommatePostsProvider);
      ref.invalidate(myRoommatePostsProvider);
      ref.invalidate(roommatePostDetailProvider(postId));
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
