import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/create_room_draft.dart';
import 'providers/create_room_provider.dart';
import 'steps/property_step.dart';
import 'steps/room_cost_step.dart';
import 'steps/room_information_step.dart';
import 'steps/room_media_step.dart';
import 'steps/room_preview_step.dart';

class LandlordCreateRoomScreen extends ConsumerStatefulWidget {
  const LandlordCreateRoomScreen({super.key});
  @override
  ConsumerState<LandlordCreateRoomScreen> createState() =>
      _LandlordCreateRoomScreenState();
}

class _LandlordCreateRoomScreenState
    extends ConsumerState<LandlordCreateRoomScreen> {
  late final CreateRoomDraft _draft;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _draft = CreateRoomDraft();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  Future<void> _createDraftAndNext() async {
    final success = await ref
        .read(createRoomControllerProvider.notifier)
        .ensureDraftRoom(_draft);
    if (!mounted) return;
    if (success) {
      _next();
    } else {
      _showControllerError();
    }
  }

  Future<void> _saveMediaSpacesAndNext() async {
    final success = await ref
        .read(createRoomControllerProvider.notifier)
        .syncMediaAndSpaces(_draft);
    if (!mounted) return;
    if (success) {
      _next();
    } else {
      _showControllerError();
    }
  }

  Future<void> _saveCostsAndOpenPreview() async {
    final controller = ref.read(createRoomControllerProvider.notifier);
    final saved = await controller.saveCostsAndAmenities(_draft);
    if (!mounted) return;
    if (!saved) {
      _showControllerError();
      return;
    }
    final previewed = await controller.refreshPreview(_draft);
    if (!mounted) return;
    if (previewed) {
      _next();
    } else {
      _showControllerError();
    }
  }

  void _back() {
    if (_currentStep == 0) {
      context.pop();
    } else {
      setState(() => _currentStep--);
    }
  }

  Future<void> _persist({required bool submit}) async {
    if (!_draft.isPropertyValid ||
        !_draft.isRoomInformationValid ||
        !_draft.hasMedia) {
      _message('Thông tin phòng chưa đầy đủ.');
      return;
    }
    final success = await ref
        .read(createRoomControllerProvider.notifier)
        .finish(_draft, submit: submit);
    if (!mounted) return;
    if (!success) {
      _showControllerError();
      return;
    }
    _message(
      submit
          ? 'Đã gửi phòng lên chờ duyệt.'
          : 'Đã lưu phòng ở trạng thái bản nháp.',
    );
    context.pop(true);
  }

  void _showControllerError() {
    _message(_errorText(ref.read(createRoomControllerProvider).error));
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(landlordPropertiesProvider);
    final amenities = ref.watch(roomAmenitiesProvider);
    final action = ref.watch(createRoomControllerProvider);

    return IndexedStack(
      index: _currentStep,
      children: [
        PropertyStep(
          draft: _draft,
          properties: properties.value ?? const [],
          isLoadingProperties: properties.isLoading,
          onRetryProperties: () => ref.invalidate(landlordPropertiesProvider),
          onClose: () => context.pop(),
          onNext: _next,
        ),
        RoomInformationStep(
          draft: _draft,
          onBack: _back,
          onNext: _createDraftAndNext,
          onChangeProperty: () => setState(() => _currentStep = 0),
          isSaving: action.isLoading,
        ),
        RoomMediaStep(
          draft: _draft,
          onBack: _back,
          onNext: _saveMediaSpacesAndNext,
          isSaving: action.isLoading,
        ),
        RoomCostStep(
          draft: _draft,
          amenities: amenities.value ?? const [],
          isLoadingAmenities: amenities.isLoading,
          onRetryAmenities: () => ref.invalidate(roomAmenitiesProvider),
          onBack: _back,
          onNext: _saveCostsAndOpenPreview,
          isSaving: action.isLoading,
        ),
        RoomPreviewStep(
          draft: _draft,
          onBack: _back,
          onSaveDraft: () => _persist(submit: false),
          onSubmit: () => _persist(submit: true),
          isSubmitting: action.isLoading,
        ),
      ],
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

String _errorText(Object? error) {
  if (error == null) return 'Không thể đăng phòng. Vui lòng thử lại.';
  return error.toString().replaceFirst('Exception: ', '');
}
