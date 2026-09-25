import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/room_summary.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    required this.room,
    required this.onTap,
    required this.onFavoritePressed,
    this.isFavorite = false,
    super.key,
  });

  final RoomSummary room;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  room.imageUrl == null
                      ? const _ImageFallback()
                      : Image.network(
                          room.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ImageFallback(),
                        ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (room.isVerified)
                          const _ImageBadge(
                            icon: Icons.verified_rounded,
                            text: 'Đã xác thực',
                          ),
                        if (room.hasVideo)
                          const _ImageBadge(
                            icon: Icons.videocam_outlined,
                            text: 'Có video',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: onFavoritePressed,
                        tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu phòng',
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? colors.error : null,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${formatVnd(room.priceMonthly)}/tháng',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatusChip(
                        icon: Icons.check_circle_outline_rounded,
                        text: _confirmationLabel(room.lastConfirmedAt),
                        positive: room.lastConfirmedAt != null,
                      ),
                      if (room.distanceMeters != null)
                        _StatusChip(
                          icon: Icons.near_me_outlined,
                          text: _distanceLabel(room.distanceMeters!),
                          positive: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.square_foot, size: 18),
                      const SizedBox(width: 4),
                      Text('${room.areaM2.toStringAsFixed(0)} m²'),
                      const SizedBox(width: 16),
                      const Icon(Icons.bed_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text(_roomTypeLabel(room.roomType)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          room.fullAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _confirmationLabel(DateTime? value) {
  if (value == null) return 'Chưa xác nhận gần đây';
  final days = DateTime.now().difference(value.toLocal()).inDays;
  if (days <= 0) return 'Xác nhận còn phòng hôm nay';
  if (days == 1) return 'Xác nhận còn phòng hôm qua';
  return 'Xác nhận còn phòng $days ngày trước';
}

String _distanceLabel(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _roomTypeLabel(String value) => switch (value) {
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 phòng ngủ',
  'SINGLE' => 'Phòng đơn',
  'SHARED' => 'Phòng ghép',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => value,
};

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.home_work_outlined, size: 56)),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .68),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.text,
    required this.positive,
  });

  final IconData icon;
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF008E78) : const Color(0xFF7A8794);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
