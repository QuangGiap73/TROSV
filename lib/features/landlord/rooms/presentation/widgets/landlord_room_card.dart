import 'package:flutter/material.dart';

import '../../domain/entities/landlord_room.dart';

const _greenDark = Color(0xFF008C72);
const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF667773);

const _cardRadius = 16.0;
const _imageRadius = 13.0;
const _imageSize = 112.0;

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: const Color(0xFFE3EBE8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoomImage(room: room),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _RoomContent(
                        room: room,
                        actions: actions,
                        onAction: onAction,
                      ),
                    ),
                  ],
                ),

                if (room.rejectionReason?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _RejectionBox(
                    reason: room.rejectionReason!.trim(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomContent extends StatelessWidget {
  const _RoomContent({
    required this.room,
    required this.actions,
    required this.onAction,
  });

  final LandlordRoom room;
  final List<LandlordRoomAction> actions;
  final ValueChanged<LandlordRoomAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        //
        // TITLE + MENU
        //
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  room.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),
            ),

            if (actions.isNotEmpty) ...[
              const SizedBox(width: 4),
              _RoomActionMenu(
                actions: actions,
                onAction: onAction,
              ),
            ],
          ],
        ),

        //
        // PRICE
        //
        const SizedBox(height: 3),

        Text(
          '${_money(room.priceMonthly)} đ/tháng',
          style: const TextStyle(
            color: _greenDark,
            fontSize: 15.5,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),

        //
        // AREA + PEOPLE
        //
        const SizedBox(height: 6),

        Wrap(
          spacing: 12,
          runSpacing: 4,
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

        //
        // ADDRESS
        //
        if (room.fullAddress.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFF7A8A86),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  room.fullAddress.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],

        //
        // STATUS
        //
        const SizedBox(height: 8),

        _StatusChip(
          status: room.status,
        ),
      ],
    );
  }
}

class _RoomActionMenu extends StatelessWidget {
  const _RoomActionMenu({
    required this.actions,
    required this.onAction,
  });

  final List<LandlordRoomAction> actions;
  final ValueChanged<LandlordRoomAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LandlordRoomAction>(
      tooltip: 'Thao tác',
      position: PopupMenuPosition.under,
      onSelected: onAction,
      itemBuilder: (_) {
        return actions.map((action) {
          return PopupMenuItem<LandlordRoomAction>(
            value: action,
            height: 44,
            child: Row(
              children: [
                Icon(
                  _actionIcon(action),
                  size: 18,
                  color: _actionColor(action),
                ),
                const SizedBox(width: 10),
                Text(
                  _actionLabel(action),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: action == LandlordRoomAction.delete
                        ? Colors.redAccent
                        : _textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },

      // Dùng child thay vì icon để tránh PopupMenuButton
      // tự chiếm vùng 48x48 gây khoảng trắng thừa.
      child: const SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: Color(0xFF657571),
          ),
        ),
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({
    required this.room,
  });

  final LandlordRoom room;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_imageRadius),
      child: SizedBox(
        width: _imageSize,
        height: _imageSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (room.imageUrl == null || room.imageUrl!.trim().isEmpty)
              const _RoomImagePlaceholder()
            else
              Image.network(
                room.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const _RoomImagePlaceholder(
                    broken: true,
                  );
                },
              ),

            //
            // Gradient rất nhẹ phía dưới để ảnh có chiều sâu.
            //
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 32,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder({
    this.broken = false,
  });

  final bool broken;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE9F4F1),
      child: Center(
        child: Icon(
          broken
              ? Icons.broken_image_outlined
              : Icons.home_work_outlined,
          size: broken ? 29 : 34,
          color: const Color(0xFF76A49A),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.5,
          color: const Color(0xFF71837E),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.2,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: config.color.withOpacity(0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 12.5,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 10.2,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectionBox extends StatelessWidget {
  const _RejectionBox({
    required this.reason,
  });

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFDADA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: Colors.redAccent,
            ),
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

typedef _StatusConfig = ({
  String label,
  Color color,
  IconData icon,
});

_StatusConfig _statusConfig(String status) {
  return switch (status) {
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
    'RENTED' => (
        label: 'Đã thuê',
        color: Colors.indigo,
        icon: Icons.key_rounded,
      ),
    'CANCELLED' => (
        label: 'Đã hủy',
        color: Colors.brown,
        icon: Icons.cancel_rounded,
      ),
    _ => (
        label: status,
        color: Colors.grey,
        icon: Icons.info_outline_rounded,
      ),
  };
}

List<LandlordRoomAction> _availableActions(String status) {
  return switch (status) {
    'DRAFT' || 'REJECTED' => const [
        LandlordRoomAction.submit,
        LandlordRoomAction.delete,
      ],
    'PUBLISHED' => const [
        LandlordRoomAction.confirmAvailability,
        LandlordRoomAction.hide,
        LandlordRoomAction.markRented,
      ],
    'HIDDEN' => const [
        LandlordRoomAction.show,
        LandlordRoomAction.delete,
      ],
    'RENTED' => const [
        LandlordRoomAction.unmarkRented,
      ],
    _ => const [],
  };
}

String _actionLabel(LandlordRoomAction action) {
  return switch (action) {
    LandlordRoomAction.submit => 'Gửi duyệt',
    LandlordRoomAction.show => 'Hiện phòng',
    LandlordRoomAction.hide => 'Ẩn phòng',
    LandlordRoomAction.confirmAvailability => 'Xác nhận còn trống',
    LandlordRoomAction.markRented => 'Đánh dấu đã thuê',
    LandlordRoomAction.unmarkRented => 'Đánh dấu còn trống',
    LandlordRoomAction.delete => 'Hủy phòng',
  };
}

IconData _actionIcon(LandlordRoomAction action) {
  return switch (action) {
    LandlordRoomAction.submit => Icons.send_rounded,
    LandlordRoomAction.show => Icons.visibility_rounded,
    LandlordRoomAction.hide => Icons.visibility_off_rounded,
    LandlordRoomAction.confirmAvailability =>
      Icons.event_available_rounded,
    LandlordRoomAction.markRented => Icons.key_rounded,
    LandlordRoomAction.unmarkRented => Icons.home_work_rounded,
    LandlordRoomAction.delete => Icons.delete_outline_rounded,
  };
}

Color _actionColor(LandlordRoomAction action) {
  if (action == LandlordRoomAction.delete) {
    return Colors.redAccent;
  }

  return _greenDark;
}

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