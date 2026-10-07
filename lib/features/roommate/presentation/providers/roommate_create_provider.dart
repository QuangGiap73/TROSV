import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  void addImages(List<XFile> files) {
    state = state.copyWith(imageFiles: [...state.imageFiles, ...files]);
  }

  void removeImage(int index) {
    final images = [...state.imageFiles]..removeAt(index);
    state = state.copyWith(imageFiles: images);
  }

  void setVideo(XFile? file) {
    state = state.copyWith(videoFiles: file == null ? const [] : [file]);
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
  FutureOr<String?> build() => null;

  Future<String?> submit() async {
    if (state.isLoading) return null;

    final draft = ref.read(roommateCreateDraftProvider);

    state = const AsyncLoading();

    try {
      final repository = ref.read(roommateRepositoryProvider);
      final uploadedUrls = <String>[];
      for (final file in [...draft.imageFiles, ...draft.videoFiles]) {
        uploadedUrls.add(await repository.uploadMedia(file));
      }
      final request = draft
          .copyWith(mediaUrls: [...draft.mediaUrls, ...uploadedUrls])
          .toRequest();
      final post = await ref
          .read(roommateRepositoryProvider)
          .createPost(request);

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
