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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 205,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 126,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _RoomImage(url: room.imageUrl),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: .94),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onFavoriteTap,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: isFavorite
                                  ? const Color(0xFFE8506A)
                                  : const Color(0xFF84908D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17201E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatVnd(room.priceMonthly)}/tháng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF008E79),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.square_foot_rounded,
                            size: 15,
                            color: Color(0xFF71807C),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${room.areaM2.toStringAsFixed(0)} m²',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71807C),
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Icon(
                            Icons.bed_outlined,
                            size: 15,
                            color: Color(0xFF71807C),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _roomType(room.roomType),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF71807C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Color(0xFF71807C),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _shortAddress(room),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF71807C),
                              ),
                            ),
                          ),
                          if (room.distanceMeters != null) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.near_me_outlined,
                              size: 14,
                              color: Color(0xFF008E79),
                            ),
                            Text(
                              _distance(room.distanceMeters!),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF008E79),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
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
  const _RoomImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) return const _ImageFallback();
    final cacheWidth = (205 * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(410, 820);
    return Image.network(
      url!,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE7EEEC),
    child: Center(
      child: Icon(Icons.home_work_outlined, size: 40, color: Color(0xFF82928E)),
    ),
  );
}

String _shortAddress(RoomSummary room) {
  final parts = [
    room.district,
    room.province,
  ].where((part) => part.trim().isNotEmpty).toList();
  return parts.isEmpty ? room.addressText : parts.join(', ');
}

String _distance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _roomType(String value) => switch (value) {
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 PN',
  'SINGLE' => 'Phòng đơn',
  'SHARED' || 'ROOM_SHARED' => 'Ở ghép',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => value,
};
