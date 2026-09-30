import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/landlord_room_detail.dart';
import '../providers/landlord_room_action_provider.dart';
import '../providers/landlord_room_provider.dart';
import '../widgets/detail/landlord_room_action_menu.dart';
import '../widgets/detail/landlord_room_amenity_grid.dart';
import '../widgets/detail/landlord_room_media_gallery.dart';
import '../widgets/detail/landlord_room_ui.dart';

class LandlordRoomOverviewScreen extends ConsumerWidget {
  const LandlordRoomOverviewScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(landlordRoomDetailProvider(roomId));
    final actionBusy = ref.watch(landlordRoomActionLoadingProvider(roomId));

    final refreshing = detail.isRefreshing;

    return Scaffold(
      backgroundColor: roomBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: roomBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Phòng của tôi',
          style: TextStyle(fontWeight: FontWeight.w900, color: roomText),
        ),
        actions: [
          detail.maybeWhen(
            data: (room) => LandlordRoomActionMenu(
              roomId: room.id,
              roomTitle: room.title,
              status: room.status,
              onDeleted: () {
                if (context.canPop()) {
                  context.pop(true);
                }
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: actionBusy || refreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: roomGreen,
                  backgroundColor: Color(0xFFDDF1EB),
                ),
              )
            : null,
      ),
      body: detail.when(
        skipLoadingOnRefresh: true,
        loading: () => const LandlordRoomDetailLoading(),
        error: (error, _) => LandlordRoomDetailError(
          message: roomErrorText(error),
          onRetry: () => _refresh(ref),
        ),
        data: (room) {
          return RefreshIndicator(
            color: roomGreen,
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
              children: [
                LandlordRoomMediaGallery(room: room),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        room.title,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          color: roomText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    LandlordRoomStatusBadge(status: room.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${roomMoney(room.priceMonthly)} đ/tháng',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: roomGreenDark,
                  ),
                ),
                const SizedBox(height: 14),
                _QuickFacts(room: room),
                if (room.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _LocationCard(address: room.fullAddress),
                ],
                if (room.status == 'REJECTED' &&
                    room.rejectionReason?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _RejectedCard(reason: room.rejectionReason!),
                ],
                if (room.amenities.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _AmenitiesPreview(room: room),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: detail.maybeWhen(
        data: (room) => SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: roomBorder)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 14,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: roomGreenDark,
                      side: const BorderSide(color: roomGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text(
                      'Chỉnh sửa',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/landlord/rooms/${room.id}/detail');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: roomGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text(
                      'Xem chi tiết',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(landlordRoomDetailProvider(roomId));

    try {
      await ref.read(landlordRoomDetailProvider(roomId).future);
    } catch (_) {
      // AsyncValue phía trên sẽ hiển thị lỗi.
    }
  }
}

class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.room});

  final LandlordRoomDetail room;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: roomBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickFact(
              icon: Icons.square_foot_rounded,
              value: '${roomDecimal(room.areaM2)} m²',
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _QuickFact(
              icon: Icons.layers_outlined,
              value: room.floor == null ? 'Chưa rõ tầng' : 'Tầng ${room.floor}',
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _QuickFact(
              icon: Icons.people_alt_outlined,
              value: '${room.maxPeople} người',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFact extends StatelessWidget {
  const _QuickFact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: roomGreenDark),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: roomText,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0xFFE8EEEC));
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD5ECE6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.location_on_rounded, color: roomGreenDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vị trí phòng',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: roomText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: roomMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  const _RejectedCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDCD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Lý do từ chối: $reason',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF8D3B3B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesPreview extends StatelessWidget {
  const _AmenitiesPreview({required this.room});

  final LandlordRoomDetail room;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: roomBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F3EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.weekend_outlined,
                    size: 19,
                    color: roomGreenDark,
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiện ích',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: roomText,
                        ),
                      ),
                      Text(
                        'Các tiện ích có trong phòng',
                        style: TextStyle(fontSize: 10, color: roomMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LandlordRoomAmenityGrid(amenities: room.amenities),
        ],
      ),
    );
  }
}
