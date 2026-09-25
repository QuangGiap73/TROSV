import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../rooms/domain/entities/room_summary.dart';

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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 116,
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 116,
              child: _RoomImage(url: room.imageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onFavoriteTap,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: const Color(0xFFEF4056),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${formatVnd(room.priceMonthly)}/tháng',
                      style: const TextStyle(
                        color: Color(0xFF008E79),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${room.areaM2.toStringAsFixed(0)} m²  ·  ${_type(room.roomType)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667571),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF667571),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _address(room),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF667571),
                            ),
                          ),
                        ),
                        if (room.distanceMeters != null) ...[
                          const Icon(
                            Icons.near_me_outlined,
                            size: 13,
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

class _RoomImage extends StatelessWidget {
  const _RoomImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const _Fallback();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _Fallback(),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE5ECEA),
    child: Icon(Icons.home_work_outlined, color: Color(0xFF81908C)),
  );
}

String _address(RoomSummary room) {
  final parts = [
    room.district,
    room.province,
  ].where((value) => value.trim().isNotEmpty).toList();
  return parts.isEmpty ? room.addressText : parts.join(', ');
}

String _distance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

String _type(String value) => switch (value) {
  'ROOM_SINGLE' || 'SINGLE' => 'Phòng đơn',
  'ROOM_SHARED' || 'SHARED' => 'Ở ghép',
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => '1 phòng ngủ',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => value,
};
