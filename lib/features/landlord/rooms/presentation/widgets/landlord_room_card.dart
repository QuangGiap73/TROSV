import 'package:flutter/material.dart';

import '../../domain/entities/landlord_room.dart';

const _greenDark = Color(0xFF008C72);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);

enum LandlordRoomAction {
  submit,
  show,
  hide,
  confirmAvailability,
  markRented,
  unmarkRented,
  delete,
}

class LandlordRoomCard extends StatelessWidget {
  const LandlordRoomCard({
    required this.room,
    required this.onAction,
    this.onTap,
    super.key,
  });

  final LandlordRoom room;
  final ValueChanged<LandlordRoomAction> onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final actions = _availableActions(room.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE2EAE8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoomImage(room: room),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        if (actions.isNotEmpty)
                          PopupMenuButton<LandlordRoomAction>(
                            tooltip: 'Thao tác',
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert_rounded, size: 20),
                            onSelected: onAction,
                            itemBuilder: (_) => actions
                                .map(
                                  (action) => PopupMenuItem(
                                    value: action,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _actionIcon(action),
                                          size: 19,
                                          color: _actionColor(action),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(_actionLabel(action)),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_money(room.priceMonthly)} đ/tháng',
                      style: const TextStyle(
                        color: _greenDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 9,
                      runSpacing: 5,
                      children: [
                        _MiniInfo(
                          icon: Icons.square_foot_rounded,
                          text: '${_area(room.areaM2)} m²',
                        ),
                        _MiniInfo(
                          icon: Icons.people_alt_outlined,
                          text: '${room.maxPeople} người',
                        ),
                      ],
                    ),
                    if (room.fullAddress.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF7D8C88),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              room.fullAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _StatusChip(status: room.status),
                        const Spacer(),
                        if (onTap != null)
                          const Row(
                            children: [
                              Text(
                                'Chi tiết',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _greenDark,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 17,
                                color: _greenDark,
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (room.rejectionReason?.isNotEmpty == true) ...[
                      const SizedBox(height: 9),
                      _RejectionBox(reason: room.rejectionReason!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({required this.room});

  final LandlordRoom room;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: 105,
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (room.imageUrl == null || room.imageUrl!.isEmpty)
              const ColoredBox(
                color: Color(0xFFE8F4F1),
                child: Icon(
                  Icons.home_work_outlined,
                  size: 36,
                  color: Color(0xFF76A49A),
                ),
              )
            else
              Image.network(
                room.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE8F4F1),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF76A49A),
                  ),
                ),
              ),
            Positioned(
              left: 7,
              bottom: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Phòng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF71837E)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: _textSecondary)),
      ],
    );
  }
}

class _RejectionBox extends StatelessWidget {
  const _RejectionBox({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD3D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.3,
                color: Color(0xFF9C3B3B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 13, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _StatusConfig = ({String label, Color color, IconData icon});

_StatusConfig _statusConfig(String status) => switch (status) {
  'DRAFT' => (
    label: 'Bản nháp',
    color: Colors.blueGrey,
    icon: Icons.edit_note_rounded,
  ),
  'PENDING_REVIEW' => (
    label: 'Chờ duyệt',
    color: Colors.orange,
    icon: Icons.schedule_rounded,
  ),
  'PUBLISHED' => (
    label: 'Đang đăng',
    color: Colors.green,
    icon: Icons.check_circle_rounded,
  ),
  'REJECTED' => (
    label: 'Bị từ chối',
    color: Colors.redAccent,
    icon: Icons.error_rounded,
  ),
  'HIDDEN' => (
    label: 'Đã ẩn',
    color: Colors.grey,
    icon: Icons.visibility_off_rounded,
  ),
  'RENTED' => (label: 'Đã thuê', color: Colors.indigo, icon: Icons.key_rounded),
  'CANCELLED' => (
    label: 'Đã hủy',
    color: Colors.brown,
    icon: Icons.cancel_rounded,
  ),
  _ => (label: status, color: Colors.grey, icon: Icons.info_outline_rounded),
};

List<LandlordRoomAction> _availableActions(String status) => switch (status) {
  'DRAFT' ||
  'REJECTED' => const [LandlordRoomAction.submit, LandlordRoomAction.delete],
  'PUBLISHED' => const [
    LandlordRoomAction.confirmAvailability,
    LandlordRoomAction.hide,
    LandlordRoomAction.markRented,
  ],
  'HIDDEN' => const [LandlordRoomAction.show, LandlordRoomAction.delete],
  'RENTED' => const [LandlordRoomAction.unmarkRented],
  _ => const [],
};

String _actionLabel(LandlordRoomAction action) => switch (action) {
  LandlordRoomAction.submit => 'Gửi duyệt',
  LandlordRoomAction.show => 'Hiện phòng',
  LandlordRoomAction.hide => 'Ẩn phòng',
  LandlordRoomAction.confirmAvailability => 'Xác nhận còn trống',
  LandlordRoomAction.markRented => 'Đánh dấu đã thuê',
  LandlordRoomAction.unmarkRented => 'Đánh dấu còn trống',
  LandlordRoomAction.delete => 'Hủy phòng',
};

IconData _actionIcon(LandlordRoomAction action) => switch (action) {
  LandlordRoomAction.submit => Icons.send_rounded,
  LandlordRoomAction.show => Icons.visibility_rounded,
  LandlordRoomAction.hide => Icons.visibility_off_rounded,
  LandlordRoomAction.confirmAvailability => Icons.event_available_rounded,
  LandlordRoomAction.markRented => Icons.key_rounded,
  LandlordRoomAction.unmarkRented => Icons.home_work_rounded,
  LandlordRoomAction.delete => Icons.delete_outline_rounded,
};

Color _actionColor(LandlordRoomAction action) =>
    action == LandlordRoomAction.delete ? Colors.redAccent : _greenDark;

String _money(int value) {
  final digits = value.toString();
  final output = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      output.write('.');
    }

    output.write(digits[index]);
  }

  return output.toString();
}

String _area(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}
