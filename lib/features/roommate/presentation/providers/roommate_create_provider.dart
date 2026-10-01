import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/roommate_create_draft.dart';
import 'roommate_provider.dart';

final roommateCreateDraftProvider =
    NotifierProvider<RoommateCreateDraftController, RoommateCreateDraft>(
      RoommateCreateDraftController.new,
    );

class RoommateCreateDraftController extends Notifier<RoommateCreateDraft> {
  @override
  RoommateCreateDraft build() {
    return RoommateCreateDraft(
      moveInDate: DateTime.now().add(const Duration(days: 7)),
    );
  }

  void update(RoommateCreateDraft value) {
    state = value;
  }

  void nextStep() {
    if (state.step < 2) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void previousStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  void goToStep(int step) {
    state = state.copyWith(step: step.clamp(0, 2));
  }

  void toggleTag(String tag) {
    final tags = {...state.lifestyleTags};

    if (!tags.add(tag)) {
      tags.remove(tag);
    }

    state = state.copyWith(lifestyleTags: tags);
  }

  void reset() {
    state = RoommateCreateDraft(
      moveInDate: DateTime.now().add(const Duration(days: 7)),
    );
  }
}

final submitRoommatePostProvider =
    AsyncNotifierProvider<SubmitRoommatePostController, String?>(
      SubmitRoommatePostController.new,
    );

class SubmitRoommatePostController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> submit() async {
    if (state.isLoading) return null;

    final draft = ref.read(roommateCreateDraftProvider);

    state = const AsyncLoading();

    try {
      final post = await ref
          .read(roommateRepositoryProvider)
          .createPost(draft.toRequest());

      state = AsyncData(post.id);

      ref.invalidate(roommatePostsProvider);
      ref.invalidate(myRoommatePostsProvider);

      return post.id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
