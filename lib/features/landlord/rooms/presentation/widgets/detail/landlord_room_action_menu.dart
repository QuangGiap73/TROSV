import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/landlord_room_action_provider.dart';
import 'landlord_room_ui.dart';

enum LandlordRoomManageAction {
  submit,
  show,
  hide,
  confirmAvailability,
  markRented,
  unmarkRented,
  delete,
}

class LandlordRoomActionMenu extends ConsumerWidget {
  const LandlordRoomActionMenu({
    required this.roomId,
    required this.roomTitle,
    required this.status,
    this.onDeleted,
    super.key,
  });

  final String roomId;
  final String roomTitle;
  final String status;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(landlordRoomActionLoadingProvider(roomId));
    final actions = _availableActions(status);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<LandlordRoomManageAction>(
      enabled: !busy,
      tooltip: 'Quản lý phòng',
      icon: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: roomGreenDark,
              ),
            )
          : const Icon(Icons.more_vert_rounded),
      onSelected: (action) => _perform(context, ref, action),
      itemBuilder: (_) {
        return actions
            .map(
              (action) => PopupMenuItem(
                value: action,
                child: Row(
                  children: [
                    Icon(
                      _icon(action),
                      size: 20,
                      color: _dangerous(action) ? Colors.redAccent : roomText,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _label(action),
                      style: TextStyle(
                        color: _dangerous(action) ? Colors.redAccent : roomText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
    );
  }

  Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    LandlordRoomManageAction action,
  ) async {
    if (_needsConfirm(action)) {
      final accepted = await _confirm(context, action);
      if (!accepted || !context.mounted) return;
    }

    final controller = ref.read(landlordRoomActionProvider.notifier);

    final success = switch (action) {
      LandlordRoomManageAction.submit => await controller.submitRoom(roomId),
      LandlordRoomManageAction.show => await controller.updateVisibility(
        roomId,
        visible: true,
      ),
      LandlordRoomManageAction.hide => await controller.updateVisibility(
        roomId,
        visible: false,
      ),
      LandlordRoomManageAction.confirmAvailability =>
        await controller.confirmAvailability(roomId),
      LandlordRoomManageAction.markRented => await controller.markRented(
        roomId,
      ),
      LandlordRoomManageAction.unmarkRented => await controller.unmarkRented(
        roomId,
      ),
      LandlordRoomManageAction.delete => await controller.deleteRoom(roomId),
    };

    if (!context.mounted) return;

    if (success && action == LandlordRoomManageAction.delete) {
      onDeleted?.call();
      return;
    }

    final text = success
        ? _successMessage(action)
        : roomErrorText(ref.read(landlordRoomActionErrorProvider(roomId)));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  Future<bool> _confirm(
    BuildContext context,
    LandlordRoomManageAction action,
  ) async {
    return await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE5E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    _dangerous(action)
                        ? Icons.warning_amber_rounded
                        : _icon(action),
                    size: 40,
                    color: _dangerous(action)
                        ? Colors.redAccent
                        : roomGreenDark,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _label(action),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: roomText,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Bạn có chắc muốn ${_label(action).toLowerCase()} “$roomTitle”?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: roomMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text('Quay lại'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: _dangerous(action)
                                ? Colors.redAccent
                                : roomGreen,
                          ),
                          child: const Text('Xác nhận'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }
}

List<LandlordRoomManageAction> _availableActions(String status) =>
    switch (status) {
      'DRAFT' => const [
        LandlordRoomManageAction.submit,
        LandlordRoomManageAction.delete,
      ],
      'REJECTED' => const [
        LandlordRoomManageAction.submit,
        LandlordRoomManageAction.delete,
      ],
      'PUBLISHED' => const [
        LandlordRoomManageAction.confirmAvailability,
        LandlordRoomManageAction.hide,
        LandlordRoomManageAction.markRented,
      ],
      'HIDDEN' => const [
        LandlordRoomManageAction.show,
        LandlordRoomManageAction.delete,
      ],
      'RENTED' => const [LandlordRoomManageAction.unmarkRented],
      'CANCELLED' => const [LandlordRoomManageAction.delete],
      _ => const [],
    };

bool _needsConfirm(LandlordRoomManageAction action) {
  return {
    LandlordRoomManageAction.hide,
    LandlordRoomManageAction.markRented,
    LandlordRoomManageAction.unmarkRented,
    LandlordRoomManageAction.delete,
  }.contains(action);
}

bool _dangerous(LandlordRoomManageAction action) {
  return action == LandlordRoomManageAction.delete;
}

String _label(LandlordRoomManageAction action) => switch (action) {
  LandlordRoomManageAction.submit => 'Gửi duyệt',
  LandlordRoomManageAction.show => 'Hiện phòng',
  LandlordRoomManageAction.hide => 'Ẩn phòng',
  LandlordRoomManageAction.confirmAvailability => 'Xác nhận còn trống',
  LandlordRoomManageAction.markRented => 'Đánh dấu đã thuê',
  LandlordRoomManageAction.unmarkRented => 'Chuyển về còn trống',
  LandlordRoomManageAction.delete => 'Xóa phòng',
};

IconData _icon(LandlordRoomManageAction action) => switch (action) {
  LandlordRoomManageAction.submit => Icons.send_rounded,
  LandlordRoomManageAction.show => Icons.visibility_rounded,
  LandlordRoomManageAction.hide => Icons.visibility_off_rounded,
  LandlordRoomManageAction.confirmAvailability => Icons.event_available_rounded,
  LandlordRoomManageAction.markRented => Icons.key_rounded,
  LandlordRoomManageAction.unmarkRented => Icons.home_work_rounded,
  LandlordRoomManageAction.delete => Icons.delete_outline_rounded,
};

String _successMessage(LandlordRoomManageAction action) => switch (action) {
  LandlordRoomManageAction.submit => 'Đã gửi phòng lên chờ duyệt.',
  LandlordRoomManageAction.show => 'Đã hiển thị phòng.',
  LandlordRoomManageAction.hide => 'Đã ẩn phòng.',
  LandlordRoomManageAction.confirmAvailability =>
    'Đã xác nhận phòng còn trống.',
  LandlordRoomManageAction.markRented => 'Đã đánh dấu phòng đã thuê.',
  LandlordRoomManageAction.unmarkRented =>
    'Đã chuyển phòng về trạng thái còn trống.',
  LandlordRoomManageAction.delete => 'Đã xóa phòng.',
};
