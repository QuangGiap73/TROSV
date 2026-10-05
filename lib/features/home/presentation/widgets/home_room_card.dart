import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../rooms/domain/entities/room_summary.dart';

class HomeRoomCard extends StatelessWidget {
  const HomeRoomCard({
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

  static const _green = Color(0xFF00A884);
  static const _greenDark = Color(0xFF008C72);
  static const _text = Color(0xFF17211F);
  static const _muted = Color(0xFF71807C);
  static const _border = Color(0xFFE3ECE9);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoomImage(
                room: room,
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  11,
                  9,
                  11,
                  9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${formatVnd(room.priceMonthly)}/tháng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: _greenDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _shortAddress(room),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoItem(
                          icon: Icons.square_foot_rounded,
                          text: '${_area(room.areaM2)} m²',
                        ),
                        _Dot(),
                        _InfoItem(
                          icon: Icons.bed_outlined,
                          text: _roomType(room.roomType),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    _AvailabilityRow(
                      lastConfirmedAt: room.lastConfirmedAt,
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
  const _RoomImage({
    required this.room,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final RoomSummary room;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetworkRoomImage(url: room.imageUrl),

          Positioned(
            top: 8,
            left: 8,
            child: Wrap(
              spacing: 5,
              children: [
                if (room.isVerified)
                  const _ImageBadge(
                    icon: Icons.verified_rounded,
                    text: 'Xác thực',
                    background: Color(0xFF00A884),
                  ),

                if (room.hasVideo)
                  const _ImageBadge(
                    icon: Icons.play_arrow_rounded,
                    text: 'Có video',
                    background: Color(0xCC243B36),
                  ),
              ],
            ),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white.withValues(alpha: .96),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: onFavoriteTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFavorite
                        ? const Color(0xFFE8506A)
                        : const Color(0xFF465653),
                  ),
                ),
              ),
            ),
          ),

          if (room.distanceMeters != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .62),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _distance(room.distanceMeters!),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NetworkRoomImage extends StatelessWidget {
  const _NetworkRoomImage({
    required this.url,
  });

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const _ImageFallback();
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    final cacheWidth = (220 * pixelRatio)
        .round()
        .clamp(440, 880);

    return Image.network(
      url!,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) =>
          const _ImageFallback(),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({
    required this.icon,
    required this.text,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
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
          size: 13,
          color: HomeRoomCard._muted,
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 9.8,
            color: HomeRoomCard._muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFFA8B3B0),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.lastConfirmedAt,
  });

  final DateTime? lastConfirmedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF18B981),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _availabilityText(lastConfirmedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF008E79),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE7EEEC),
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 40,
          color: Color(0xFF82928E),
        ),
      ),
    );
  }
}

String _shortAddress(RoomSummary room) {
  final parts = [
    room.district,
    room.province,
  ].where(
    (part) => part.trim().isNotEmpty,
  ).toList();

  if (parts.isNotEmpty) {
    return parts.join(', ');
  }

  return room.addressText;
}

String _distance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }

  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _area(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}

String _roomType(String value) => switch (value) {
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 PN',

  'ROOM_SINGLE' ||
  'SINGLE' => 'Phòng đơn',

  'ROOM_SHARED' ||
  'SHARED' => 'Ở ghép',

  'WHOLE_HOUSE' => 'Nguyên căn',

  _ => value,
};

String _availabilityText(DateTime? value) {
  if (value == null) {
    return 'Đang cho thuê';
  }

  final days = DateTime.now()
      .difference(value.toLocal())
      .inDays;

  if (days <= 0) {
    return 'Còn phòng · hôm nay';
  }

  if (days == 1) {
    return 'Còn phòng · hôm qua';
  }

  if (days <= 7) {
    return 'Còn phòng · $days ngày trước';
  }

  return 'Đang cho thuê';
}