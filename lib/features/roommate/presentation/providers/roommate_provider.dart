import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/roommate_remote_data_source.dart';
import '../../data/repositories/roommate_repository_impl.dart';
import '../../domain/entities/roommate_post.dart';
import '../../domain/models/create_roommate_post_request.dart';
import '../../domain/repositories/roommate_repository.dart';

final roommateRemoteDataSourceProvider = Provider(
  (ref) => RoommateRemoteDataSource(
    ref.watch(dioProvider),
  ),
);

final roommateRepositoryProvider =
    Provider<RoommateRepository>(
  (ref) => RoommateRepositoryImpl(
    ref.watch(roommateRemoteDataSourceProvider),
  ),
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

final roommatePostsProvider =
    FutureProvider.autoDispose<List<RoommatePost>>(
  (ref) {
    final filter = ref.watch(roommateFilterProvider);

    return ref.watch(roommateRepositoryProvider).getPosts(
          district: filter.district,
          minBudget: filter.minBudget,
          maxBudget: filter.maxBudget,
          gender: filter.gender,
          postType: filter.postType,
          universityOrWork: filter.universityOrWork,
        );
  },
);

final myRoommatePostsProvider =
    FutureProvider.autoDispose<List<RoommatePost>>(
  (ref) {
    return ref
        .watch(roommateRepositoryProvider)
        .getMyPosts();
  },
);

final roommatePostActionProvider =
    AsyncNotifierProvider<RoommatePostActionController, void>(
  RoommatePostActionController.new,
);

class RoommatePostActionController
    extends AsyncNotifier<void> {
  RoommateRepository get _repository {
    return ref.read(roommateRepositoryProvider);
  }

  @override
  Future<void> build() async {}

  Future<RoommatePost?> createPost(
    CreateRoommatePostRequest request,
  ) async {
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
}