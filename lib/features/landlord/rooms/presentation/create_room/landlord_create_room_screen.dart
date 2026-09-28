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
    final roomId = await ref
        .read(createRoomControllerProvider.notifier)
        .save(_draft, submit: submit);
    if (!mounted) return;
    if (roomId == null) {
      final error = ref.read(createRoomControllerProvider).error;
      _message(_errorText(error));
      return;
    }
    _message(
      submit
          ? 'Đã gửi phòng lên chờ duyệt.'
          : 'Đã lưu phòng ở trạng thái bản nháp.',
    );
    context.pop(true);
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
          onNext: _next,
          onChangeProperty: () => setState(() => _currentStep = 0),
        ),
        RoomMediaStep(draft: _draft, onBack: _back, onNext: _next),
        RoomCostStep(
          draft: _draft,
          amenities: amenities.value ?? const [],
          isLoadingAmenities: amenities.isLoading,
          onRetryAmenities: () => ref.invalidate(roomAmenitiesProvider),
          onBack: _back,
          onNext: _next,
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
