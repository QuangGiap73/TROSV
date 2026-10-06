import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../rooms/domain/entities/room_summary.dart';

const _green = Color(0xFF00A884);
const _greenDark = Color(0xFF008C72);
const _text = Color(0xFF17211F);
const _muted = Color(0xFF687571);
const _border = Color(0xFFE4ECE9);
const _chipBackground = Color(0xFFF0F8F6);

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    required this.room,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    super.key,
  });

  final RoomSummary room;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoomImageSection(
                room: room,
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.22,
                        letterSpacing: -.15,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '${formatVnd(room.priceMonthly)}/tháng',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _green,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.1,
                            ),
                          ),
                        ),

                        if (room.distanceMeters != null)
                          _DistanceChip(text: _distance(room.distanceMeters!)),
                      ],
                    ),

                    if (room.estimatedMonthlyCost case final estimated?
                        when estimated > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Chi phí dự kiến: ${formatVnd(estimated)}/tháng',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],

                    const SizedBox(height: 11),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: _muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _address(room),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.3,
                              height: 1.35,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.square_foot_rounded,
                          text: '${room.areaM2.toStringAsFixed(0)} m²',
                        ),
                        _InfoChip(
                          icon: Icons.bed_outlined,
                          text: _type(room.roomType),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    _ConfirmationChip(
                      text: _confirmationLabel(room.lastConfirmedAt),
                      positive: room.lastConfirmedAt != null,
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

class _RoomImageSection extends StatelessWidget {
  const _RoomImageSection({
    required this.room,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final RoomSummary room;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _RoomImage(url: room.imageUrl),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x28000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x22000000),
                ],
                stops: [0, .28, .72, 1],
              ),
            ),
          ),

          Positioned(
            top: 12,
            left: 12,
            right: 66,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (room.isVerified)
                  const _ImageBadge(
                    icon: Icons.verified_rounded,
                    label: 'Đã xác thực',
                    color: _greenDark,
                  ),

                if (room.hasVideo)
                  const _ImageBadge(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Có video',
                    color: Color(0xCC17211F),
                  ),
              ],
            ),
          ),

          Positioned(
            top: 11,
            right: 11,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: .12),
              child: InkWell(
                onTap: onFavoriteTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 24,
                    color: isFavorite
                        ? const Color(0xFFFF4D61)
                        : const Color(0xFF596966),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const _Fallback();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = (constraints.maxWidth * pixelRatio)
            .round()
            .clamp(1, 1440);

        return Image.network(
          url!,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const _Fallback(),
        );
      },
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE7F0EE),
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 58,
          color: Color(0xFF92A6A1),
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F6F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 15, color: _greenDark),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _greenDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _chipBackground,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _greenDark),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationChip extends StatelessWidget {
  const _ConfirmationChip({required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? _greenDark : const Color(0xFF7A8794);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.schedule_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _address(RoomSummary room) {
  final parts = [
    room.district,
    room.province,
  ].where((value) => value.trim().isNotEmpty).toList();

  return parts.isEmpty ? room.addressText : parts.join(', ');
}

String _distance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }

  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _type(String value) => switch (value) {
  'ROOM_SINGLE' || 'SINGLE' => 'Phòng đơn',
  'ROOM_SHARED' || 'SHARED' => 'Ở ghép',
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 phòng ngủ',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => value,
};

String _confirmationLabel(DateTime? value) {
  if (value == null) {
    return 'Chưa xác nhận còn phòng gần đây';
  }

  final days = DateTime.now().difference(value.toLocal()).inDays;

  if (days <= 0) {
    return 'Xác nhận còn phòng hôm nay';
  }

  if (days == 1) {
    return 'Xác nhận còn phòng hôm qua';
  }

  return 'Xác nhận còn phòng $days ngày trước';
}
