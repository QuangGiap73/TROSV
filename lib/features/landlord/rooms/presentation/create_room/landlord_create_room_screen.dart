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
import '../providers/landlord_room_provider.dart';

class LandlordCreateRoomScreen extends ConsumerStatefulWidget {
  const LandlordCreateRoomScreen({this.roomId, super.key});

  final String? roomId;
  @override
  ConsumerState<LandlordCreateRoomScreen> createState() =>
      _LandlordCreateRoomScreenState();
}

class _LandlordCreateRoomScreenState
    extends ConsumerState<LandlordCreateRoomScreen> {
  CreateRoomDraft? _draft;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.roomId == null) _draft = CreateRoomDraft();
  }

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  Future<void> _createDraftAndNext() async {
    final draft = _draft!;
    final success = await ref
        .read(createRoomControllerProvider.notifier)
        .ensureDraftRoom(draft);
    if (!mounted) return;
    if (success) {
      _next();
    } else {
      _showControllerError();
    }
  }

  Future<void> _saveMediaSpacesAndNext() async {
    final draft = _draft!;
    final success = await ref
        .read(createRoomControllerProvider.notifier)
        .syncMediaAndSpaces(draft);
    if (!mounted) return;
    if (success) {
      _next();
    } else {
      _showControllerError();
    }
  }

  Future<void> _saveCostsAndOpenPreview() async {
    final draft = _draft!;
    final controller = ref.read(createRoomControllerProvider.notifier);
    final saved = await controller.saveCostsAndAmenities(draft);
    if (!mounted) return;
    if (!saved) {
      _showControllerError();
      return;
    }
    final previewed = await controller.refreshPreview(draft);
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
    final draft = _draft!;
    if (!draft.isPropertyValid ||
        !draft.isRoomInformationValid ||
        !draft.hasMedia) {
      _message('Thông tin phòng chưa đầy đủ.');
      return;
    }
    final success = await ref
        .read(createRoomControllerProvider.notifier)
        .finish(draft, submit: submit);
    if (!mounted) return;
    if (!success) {
      _showControllerError();
      return;
    }
    _message(
      submit
          ? 'Đã lưu thay đổi và gửi phòng lên chờ duyệt.'
          : draft.isEditing
          ? 'Đã lưu thay đổi của phòng.'
          : 'Đã lưu phòng ở trạng thái bản nháp.',
    );
    context.pop(true);
  }

  void _showControllerError() {
    _message(_errorText(ref.read(createRoomControllerProvider).error));
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId;
    if (roomId != null && _draft == null) {
      final detail = ref.watch(landlordRoomDetailProvider(roomId));
      return detail.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Chỉnh sửa phòng')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorText(error), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.invalidate(landlordRoomDetailProvider(roomId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (room) {
          _draft = CreateRoomDraft.fromDetail(room);
          return _buildWizard();
        },
      );
    }
    return _buildWizard();
  }

  Widget _buildWizard() {
    final draft = _draft!;
    final properties = ref.watch(landlordPropertiesProvider);
    final amenities = ref.watch(roomAmenitiesProvider);
    final action = ref.watch(createRoomControllerProvider);

    return IndexedStack(
      index: _currentStep,
      children: [
        PropertyStep(
          draft: draft,
          properties: properties.value ?? const [],
          isLoadingProperties: properties.isLoading,
          onRetryProperties: () => ref.invalidate(landlordPropertiesProvider),
          onClose: () => context.pop(),
          onNext: _next,
        ),
        RoomInformationStep(
          draft: draft,
          onBack: _back,
          onNext: _createDraftAndNext,
          onChangeProperty: draft.isEditing
              ? () => _message('Không thể đổi khu trọ khi chỉnh sửa phòng.')
              : () => setState(() => _currentStep = 0),
          isSaving: action.isLoading,
        ),
        RoomMediaStep(
          draft: draft,
          onBack: _back,
          onNext: _saveMediaSpacesAndNext,
          isSaving: action.isLoading,
        ),
        RoomCostStep(
          draft: draft,
          amenities: amenities.value ?? const [],
          isLoadingAmenities: amenities.isLoading,
          onRetryAmenities: () => ref.invalidate(roomAmenitiesProvider),
          onBack: _back,
          onNext: _saveCostsAndOpenPreview,
          isSaving: action.isLoading,
        ),
        RoomPreviewStep(
          draft: draft,
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
