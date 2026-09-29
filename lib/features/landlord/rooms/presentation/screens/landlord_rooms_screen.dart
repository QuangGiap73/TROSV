import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/landlord_room.dart';
import '../providers/landlord_room_provider.dart';
import '../widgets/landlord_room_card.dart';
import '../widgets/landlord_room_states.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _background = Color(0xFFF7FAF9);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF6A7975);

class LandlordRoomsScreen extends ConsumerStatefulWidget {
  const LandlordRoomsScreen({super.key});

  @override
  ConsumerState<LandlordRoomsScreen> createState() =>
      _LandlordRoomsScreenState();
}

class _LandlordRoomsScreenState extends ConsumerState<LandlordRoomsScreen> {
  final _searchController = TextEditingController();

  String? _selectedStatus;
  String _query = '';

  static const _filters = <(String?, String)>[
    (null, 'Tất cả'),
    ('DRAFT', 'Bản nháp'),
    ('PENDING_REVIEW', 'Chờ duyệt'),
    ('PUBLISHED', 'Đang đăng'),
    ('REJECTED', 'Bị từ chối'),
    ('HIDDEN', 'Đã ẩn'),
    ('RENTED', 'Đã thuê'),
    ('CANCELLED', 'Đã hủy'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(landlordRoomsProvider(_selectedStatus));
    final actionState = ref.watch(landlordRoomActionProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phòng của tôi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Quản lý và theo dõi các phòng đã đăng',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: actionState.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
        bottom: actionState.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3, color: _green),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading ? null : _openCreateRoom,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Đăng phòng mới',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: rooms.when(
        loading: () => const LandlordRoomLoading(),
        error: (error, _) =>
            LandlordRoomError(message: _errorText(error), onRetry: _refresh),
        data: (items) {
          final visibleItems = _filterByQuery(items);

          return RefreshIndicator(
            color: _green,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderControls(
                    searchController: _searchController,
                    query: _query,
                    selectedStatus: _selectedStatus,
                    filters: _filters,
                    resultCount: visibleItems.length,
                    onQueryChanged: (value) {
                      setState(() {
                        _query = value.trim();
                      });
                    },
                    onClearQuery: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                      });
                    },
                    onStatusChanged: (status) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                  ),
                ),
                if (visibleItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _query.isNotEmpty
                        ? LandlordRoomSearchEmpty(
                            query: _query,
                            onClear: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                          )
                        : LandlordRoomEmpty(onCreateRoom: _openCreateRoom),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 105),
                    sliver: SliverList.separated(
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (context, index) {
                        final room = visibleItems[index];

                        return LandlordRoomCard(
                          room: room,
                          onTap: () => _openRoomDetail(room),
                          onAction: (action) => _confirmAndHandle(room, action),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<LandlordRoom> _filterByQuery(List<LandlordRoom> rooms) {
    final q = _query.toLowerCase();

    if (q.isEmpty) return rooms;

    return rooms
        .where((room) {
          return room.title.toLowerCase().contains(q) ||
              room.fullAddress.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    ref.invalidate(landlordRoomsProvider);

    try {
      await ref.read(landlordRoomsProvider(_selectedStatus).future);
    } catch (_) {
      // Provider sẽ hiển thị lỗi.
    }
  }

  Future<void> _openCreateRoom() async {
    final created = await context.push<bool>('/landlord/rooms/create');

    if (created == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _openRoomDetail(LandlordRoom room) async {
    // Khi thêm route chi tiết, màn này sẽ mở trực tiếp.
    // Route đề xuất: /landlord/rooms/:id
    final updated = await context.push<bool>('/landlord/rooms/${room.id}');

    if (updated == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _confirmAndHandle(
    LandlordRoom room,
    LandlordRoomAction action,
  ) async {
    final accepted = await _showActionConfirmation(room, action);

    if (!accepted) return;

    await _handleAction(room, action);
  }

  Future<bool> _showActionConfirmation(
    LandlordRoom room,
    LandlordRoomAction action,
  ) async {
    if (action == LandlordRoomAction.submit ||
        action == LandlordRoomAction.show) {
      return true;
    }

    final config = _confirmationConfig(action);

    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmationSheet(
        icon: config.icon,
        title: config.title,
        message: config.message.replaceAll('{room}', room.title),
        confirmLabel: config.confirmLabel,
        dangerous: config.dangerous,
      ),
    );

    return result == true;
  }

  Future<void> _handleAction(
    LandlordRoom room,
    LandlordRoomAction action,
  ) async {
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
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({
    required this.searchController,
    required this.query,
    required this.selectedStatus,
    required this.filters,
    required this.resultCount,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String query;
  final String? selectedStatus;
  final List<(String?, String)> filters;
  final int resultCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tiêu đề, địa chỉ...',
              hintStyle: const TextStyle(
                color: Color(0xFF8A9894),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearQuery,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFFE2EAE8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFFE2EAE8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: _green, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final filter = filters[index];
                final selected = selectedStatus == filter.$1;

                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => onStatusChanged(filter.$1),
                  showCheckmark: false,
                  side: BorderSide(
                    color: selected ? _green : const Color(0xFFDDE7E4),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFFE4F8F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  label: Text(
                    filter.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? _greenDark : const Color(0xFF52645F),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 11),
          Text(
            '$resultCount phòng',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.dangerous,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final bool dangerous;

  @override
  Widget build(BuildContext context) {
    final actionColor = dangerous ? Colors.redAccent : _green;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
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
              color: const Color(0xFFDDE3E1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: actionColor, size: 32),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: actionColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef _ConfirmationData = ({
  IconData icon,
  String title,
  String message,
  String confirmLabel,
  bool dangerous,
});

_ConfirmationData _confirmationConfig(
  LandlordRoomAction action,
) => switch (action) {
  LandlordRoomAction.hide => (
    icon: Icons.visibility_off_rounded,
    title: 'Ẩn phòng này?',
    message: '“{room}” sẽ tạm thời không hiển thị với người tìm trọ.',
    confirmLabel: 'Ẩn phòng',
    dangerous: false,
  ),
  LandlordRoomAction.confirmAvailability => (
    icon: Icons.event_available_rounded,
    title: 'Xác nhận phòng còn trống?',
    message:
        'Xác nhận giúp tin “{room}” luôn có trạng thái cập nhật và đáng tin cậy.',
    confirmLabel: 'Xác nhận',
    dangerous: false,
  ),
  LandlordRoomAction.markRented => (
    icon: Icons.check_circle_rounded,
    title: 'Đánh dấu đã cho thuê?',
    message:
        '“{room}” sẽ chuyển sang trạng thái đã thuê và không còn hiển thị như phòng đang trống.',
    confirmLabel: 'Đã cho thuê',
    dangerous: false,
  ),
  LandlordRoomAction.unmarkRented => (
    icon: Icons.home_work_rounded,
    title: 'Chuyển về còn trống?',
    message:
        '“{room}” sẽ được chuyển về trạng thái còn trống theo quy tắc của hệ thống.',
    confirmLabel: 'Còn trống',
    dangerous: false,
  ),
  LandlordRoomAction.delete => (
    icon: Icons.delete_outline_rounded,
    title: 'Hủy phòng này?',
    message:
        'Bạn có chắc muốn hủy “{room}”? Hành động này có thể làm phòng ngừng hoạt động.',
    confirmLabel: 'Hủy phòng',
    dangerous: true,
  ),
  _ => (
    icon: Icons.check_rounded,
    title: 'Xác nhận thao tác',
    message: 'Bạn có muốn tiếp tục?',
    confirmLabel: 'Xác nhận',
    dangerous: false,
  ),
};

String _successMessage(LandlordRoomAction action) => switch (action) {
  LandlordRoomAction.submit => 'Đã gửi phòng lên chờ duyệt.',
  LandlordRoomAction.show => 'Đã hiển thị phòng.',
  LandlordRoomAction.hide => 'Đã ẩn phòng.',
  LandlordRoomAction.confirmAvailability => 'Đã xác nhận phòng còn trống.',
  LandlordRoomAction.markRented => 'Đã đánh dấu phòng đã cho thuê.',
  LandlordRoomAction.unmarkRented => 'Đã chuyển phòng về trạng thái còn trống.',
  LandlordRoomAction.delete => 'Đã hủy phòng.',
};

String _errorText(Object? error) {
  if (error == null) {
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  return error.toString().replaceFirst('LandlordRoomFailure: ', '');
}
