import 'package:flutter/material.dart';

import '../../../rooms/domain/entities/room_summary.dart';
import '../../../../core/utils/currency_formatter.dart';

const _greenDark = Color(0xFF008C72);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF667773);

class FavoriteRoomCard extends StatelessWidget {
  const FavoriteRoomCard({
    required this.room,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final RoomSummary room;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 178,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1EBE8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: const Color(0xFFFFE9EA),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Bỏ yêu thích',
                            onPressed: onRemove,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF3E4D),
                              size: 23,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatVnd(room.priceMonthly)}/tháng',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _greenDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      text: room.fullAddress.isEmpty
                          ? 'Chưa cập nhật địa chỉ'
                          : room.fullAddress,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _CompactInfo(
                          icon: Icons.square_foot_rounded,
                          text: '${_area(room.areaM2)} m²',
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.bed_outlined,
                            text: _roomType(room.roomType),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF273D38),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        if (room.isVerified)
                          const _Tag(
                            icon: Icons.verified_outlined,
                            text: 'Đã xác thực',
                          ),
                        if (room.lastConfirmedAt != null)
                          const _Tag(
                            icon: Icons.event_available_outlined,
                            text: 'Còn phòng',
                          ),
                        if (room.hasVideo)
                          const _Tag(
                            icon: Icons.videocam_outlined,
                            text: 'Có video',
                          ),
                      ],
                    ),
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
  final RoomSummary room;

  @override
  Widget build(BuildContext context) {
    final imageCount = room.imageUrls.isNotEmpty
        ? room.imageUrls.length
        : room.imageUrl == null
        ? 0
        : 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 128,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (room.imageUrl == null)
              const ColoredBox(
                color: Color(0xFFE5F0ED),
                child: Icon(
                  Icons.home_work_outlined,
                  size: 42,
                  color: Color(0xFF779B92),
                ),
              )
            else
              Image.network(
                room.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE5F0ED),
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            if (imageCount > 0)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .64),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.photo_camera_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$imageCount ảnh',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF52645F)),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, color: _muted),
        ),
      ),
    ],
  );
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: const Color(0xFF52645F)),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF8F5),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _greenDark),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10.5,
            color: _greenDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

String _area(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _roomType(String value) => switch (value) {
  'ROOM_SINGLE' || 'SINGLE' => 'Phòng đơn',
  'ROOM_SHARED' || 'SHARED' => 'Ở ghép',
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 phòng ngủ',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => value,
};
