import 'package:flutter/material.dart';

import '../../../domain/entities/landlord_room_detail.dart';
import 'landlord_room_ui.dart';

class LandlordRoomInfoTab extends StatelessWidget {
  const LandlordRoomInfoTab({
    required this.room,
    required this.onRefresh,
    super.key,
  });

  final LandlordRoomDetail room;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: roomGreen,
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('landlord-room-info'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          if (room.status == 'REJECTED' &&
              room.rejectionReason?.trim().isNotEmpty == true)
            _RejectedNotice(reason: room.rejectionReason!),
          _BasicInfo(room: room),
          if (room.description?.trim().isNotEmpty == true)
            _TextBlock(
              title: 'Mô tả phòng',
              icon: Icons.notes_rounded,
              value: room.description!,
            ),
          if (room.houseRules?.trim().isNotEmpty == true)
            _TextBlock(
              title: 'Nội quy',
              icon: Icons.rule_rounded,
              value: room.houseRules!,
            ),
          if (room.spaces.isNotEmpty) _Spaces(room: room),
          _Tracking(room: room),
        ],
      ),
    );
  }
}

class _RejectedNotice extends StatelessWidget {
  const _RejectedNotice({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCECE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tin đăng bị từ chối',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9E2F2F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF8A4141),
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

class _BasicInfo extends StatelessWidget {
  const _BasicInfo({required this.room});

  final LandlordRoomDetail room;

  @override
  Widget build(BuildContext context) {
    return LandlordRoomSectionCard(
      title: 'Thông tin cơ bản',
      icon: Icons.meeting_room_outlined,
      child: Column(
        children: [
          _InfoRow(label: 'Tên phòng', value: room.title),
          _InfoRow(label: 'Loại phòng', value: roomTypeLabel(room.roomType)),
          _InfoRow(label: 'Diện tích', value: '${roomDecimal(room.areaM2)} m²'),
          _InfoRow(
            label: 'Tầng',
            value: room.floor?.toString() ?? 'Chưa cập nhật',
          ),
          _InfoRow(label: 'Sức chứa tối đa', value: '${room.maxPeople} người'),
          _InfoRow(
            label: 'Giá thuê',
            value: '${roomMoney(room.priceMonthly)} đ/tháng',
            emphasize: true,
          ),
          _InfoRow(
            label: 'Tiền cọc',
            value: '${roomMoney(room.depositAmount)} đ',
          ),
          _InfoRow(
            label: 'Ngày có thể vào',
            value: roomDate(room.availableDate),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 128,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, color: roomMuted),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                    color: emphasize ? roomGreenDark : roomText,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFF0F3F2)),
      ],
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.title,
    required this.icon,
    required this.value,
  });

  final String title;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LandlordRoomSectionCard(
      title: title,
      icon: icon,
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          height: 1.55,
          color: Color(0xFF44534F),
        ),
      ),
    );
  }
}

class _Spaces extends StatelessWidget {
  const _Spaces({required this.room});

  final LandlordRoomDetail room;

  @override
  Widget build(BuildContext context) {
    return LandlordRoomSectionCard(
      title: 'Không gian',
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: [
          for (var index = 0; index < room.spaces.length; index++) ...[
            _SpaceRow(space: room.spaces[index]),
            if (index != room.spaces.length - 1)
              const Divider(height: 20, color: Color(0xFFF0F3F2)),
          ],
        ],
      ),
    );
  }
}

class _SpaceRow extends StatelessWidget {
  const _SpaceRow({required this.space});

  final LandlordRoomSpace space;

  @override
  Widget build(BuildContext context) {
    final shared = space.privacyType == 'SHARED';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            roomSpaceIcon(space.spaceType),
            color: roomGreenDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roomSpaceLabel(space.spaceType),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: roomText,
                ),
              ),
              if (space.description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  space.description!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: roomMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            shared ? 'Dùng chung' : 'Riêng',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: roomGreenDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tracking extends StatelessWidget {
  const _Tracking({required this.room});

  final LandlordRoomDetail room;

  @override
  Widget build(BuildContext context) {
    return LandlordRoomSectionCard(
      title: 'Theo dõi tin đăng',
      icon: Icons.query_stats_rounded,
      child: Row(
        children: [
          Expanded(
            child: LandlordRoomFactTile(
              icon: Icons.visibility_outlined,
              label: 'Lượt xem',
              value: '${room.viewsCount} lượt',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LandlordRoomFactTile(
              icon: Icons.verified_outlined,
              label: 'Xác nhận còn trống',
              value: roomDate(room.lastConfirmedAt),
            ),
          ),
        ],
      ),
    );
  }
}
