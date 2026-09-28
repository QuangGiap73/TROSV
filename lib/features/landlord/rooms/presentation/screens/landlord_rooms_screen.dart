import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/landlord_room.dart';
import '../providers/landlord_room_provider.dart';
import '../widgets/landlord_room_card.dart';
import '../widgets/landlord_room_states.dart';

class LandlordRoomsScreen extends ConsumerStatefulWidget {
  const LandlordRoomsScreen({super.key});

  @override
  ConsumerState<LandlordRoomsScreen> createState() =>
      _LandlordRoomsScreenState();
}

class _LandlordRoomsScreenState extends ConsumerState<LandlordRoomsScreen> {
  String? _selectedStatus;

  static const _filters = <(String?, String)>[
    (null, 'Tất cả'),
    ('DRAFT', 'Bản nháp'),
    ('PENDING_REVIEW', 'Chờ duyệt'),
    ('PUBLISHED', 'Đang hiển thị'),
    ('REJECTED', 'Bị từ chối'),
    ('HIDDEN', 'Đã ẩn'),
    ('RENTED', 'Đã thuê'),
    ('CANCELLED', 'Đã hủy'),
  ];

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(landlordRoomsProvider(_selectedStatus));
    final actionState = ref.watch(landlordRoomActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: actionState.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: actionState.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading ? null : _openCreateRoom,
        icon: const Icon(Icons.add),
        label: const Text('Đăng phòng'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final filter = _filters[index];
                return ChoiceChip(
                  label: Text(filter.$2),
                  selected: _selectedStatus == filter.$1,
                  onSelected: (_) =>
                      setState(() => _selectedStatus = filter.$1),
                );
              },
            ),
          ),
          Expanded(
            child: rooms.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => LandlordRoomError(
                message: _errorText(error),
                onRetry: _refresh,
              ),
              data: (items) {
                if (items.isEmpty) {
                  return LandlordRoomEmpty(onCreateRoom: _openCreateRoom);
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    itemCount: items.length,
                    itemBuilder: (_, index) => LandlordRoomCard(
                      room: items[index],
                      onAction: (action) => _handleAction(items[index], action),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(landlordRoomsProvider);
    try {
      await ref.read(landlordRoomsProvider(_selectedStatus).future);
    } catch (_) {
      // Widget lỗi phía trên sẽ hiển thị lỗi từ provider.
    }
  }

  Future<void> _openCreateRoom() async {
    final created = await context.push<bool>('/landlord/rooms/create');
    if (created == true && mounted) await _refresh();
  }

  Future<void> _handleAction(
    LandlordRoom room,
    LandlordRoomAction action,
  ) async {
    if (action == LandlordRoomAction.delete) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa phòng?'),
          content: Text('Bạn có chắc muốn xóa “${room.title}” không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }

    final controller = ref.read(landlordRoomActionProvider.notifier);
    final success = switch (action) {
      LandlordRoomAction.submit => await controller.submitRoom(room.id),
      LandlordRoomAction.show => await controller.updateVisibility(
        room.id,
        visible: true,
      ),
      LandlordRoomAction.hide => await controller.updateVisibility(
        room.id,
        visible: false,
      ),
      LandlordRoomAction.confirmAvailability =>
        await controller.confirmAvailability(room.id),
      LandlordRoomAction.markRented => await controller.markRented(room.id),
      LandlordRoomAction.unmarkRented => await controller.unmarkRented(room.id),
      LandlordRoomAction.delete => await controller.deleteRoom(room.id),
    };

    if (!mounted) return;
    final message = success
        ? _successMessage(action)
        : _errorText(ref.read(landlordRoomActionProvider).error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _successMessage(LandlordRoomAction action) => switch (action) {
  LandlordRoomAction.submit => 'Đã gửi phòng lên chờ duyệt.',
  LandlordRoomAction.show => 'Đã hiển thị phòng.',
  LandlordRoomAction.hide => 'Đã ẩn phòng.',
  LandlordRoomAction.confirmAvailability => 'Đã xác nhận phòng còn trống.',
  LandlordRoomAction.markRented => 'Đã đánh dấu phòng đã cho thuê.',
  LandlordRoomAction.unmarkRented => 'Đã chuyển phòng về trạng thái còn trống.',
  LandlordRoomAction.delete => 'Đã xóa phòng.',
};

String _errorText(Object? error) {
  if (error == null) return 'Có lỗi xảy ra. Vui lòng thử lại.';
  return error.toString().replaceFirst('LandlordRoomFailure: ', '');
}
