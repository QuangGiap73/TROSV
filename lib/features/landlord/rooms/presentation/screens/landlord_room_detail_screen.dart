import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/landlord_room_action_provider.dart';
import '../providers/landlord_room_provider.dart';
import '../widgets/detail/landlord_room_amenities_tab.dart';
import '../widgets/detail/landlord_room_cost_tab.dart';
import '../widgets/detail/landlord_room_info_tab.dart';
import '../widgets/detail/landlord_room_media_tab.dart';
import '../widgets/detail/landlord_room_ui.dart';

class LandlordRoomDetailScreen extends ConsumerWidget {
  const LandlordRoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(landlordRoomDetailProvider(roomId));
    final actionBusy = ref.watch(landlordRoomActionLoadingProvider(roomId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: roomBackground,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: roomBackground,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Chi tiết phòng',
            style: TextStyle(fontWeight: FontWeight.w900, color: roomText),
          ),
          actions: [
            detail.maybeWhen(
              data: (room) => IconButton(
                tooltip: 'Chỉnh sửa',
                onPressed: actionBusy
                    ? null
                    : () async {
                        final changed = await context.push<bool>(
                          '/landlord/rooms/${room.id}/edit',
                        );
                        if (changed == true && context.mounted) {
                          await _refresh(ref);
                        }
                      },
                icon: const Icon(Icons.edit_outlined),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: actionBusy ? null : () => _refresh(ref),
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(51),
            child: Column(
              children: [
                if (actionBusy || detail.isRefreshing)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: roomGreen,
                    backgroundColor: Color(0xFFDDF1EB),
                  )
                else
                  const SizedBox(height: 2),
                const TabBar(
                  isScrollable: false,
                  labelColor: roomGreenDark,
                  unselectedLabelColor: roomMuted,
                  indicatorColor: roomGreen,
                  indicatorWeight: 3,
                  dividerColor: Color(0xFFE3EBE8),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: 'Thông tin'),
                    Tab(text: 'Hình ảnh'),
                    Tab(text: 'Tiện ích'),
                    Tab(text: 'Chi phí'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: detail.when(
          skipLoadingOnRefresh: true,
          loading: () => const LandlordRoomDetailLoading(),
          error: (error, _) => LandlordRoomDetailError(
            message: roomErrorText(error),
            onRetry: () => _refresh(ref),
          ),
          data: (room) {
            Future<void> refresh() => _refresh(ref);

            return TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                LandlordRoomInfoTab(room: room, onRefresh: refresh),
                LandlordRoomMediaTab(
                  room: room,
                  onRefresh: refresh,
                  onEdit: () async {
                    final changed = await context.push<bool>(
                      '/landlord/rooms/${room.id}/edit',
                    );
                    if (changed == true && context.mounted) {
                      await _refresh(ref);
                    }
                  },
                ),
                LandlordRoomAmenitiesTab(room: room, onRefresh: refresh),
                LandlordRoomCostTab(room: room, onRefresh: refresh),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(landlordRoomDetailProvider(roomId));

    try {
      await ref.read(landlordRoomDetailProvider(roomId).future);
    } catch (_) {
      // AsyncValue sẽ hiển thị lỗi.
    }
  }
}
