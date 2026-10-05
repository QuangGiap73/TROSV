import 'package:flutter/material.dart';

import '../../../rooms/domain/entities/room_summary.dart';
import 'home_room_card.dart';

class HomeRoomSection extends StatelessWidget {
  const HomeRoomSection({
    required this.title,
    required this.rooms,
    required this.favoriteIds,
    required this.onSeeAll,
    required this.onRoomTap,
    required this.onFavoriteTap,
    super.key,
  });

  final String title;
  final List<RoomSummary> rooms;
  final Set<String> favoriteIds;

  final VoidCallback onSeeAll;
  final ValueChanged<RoomSummary> onRoomTap;
  final ValueChanged<RoomSummary> onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    // Card Home nên nhỏ gọn, để lộ một phần card kế tiếp
    // giúp người dùng hiểu rằng có thể vuốt ngang.
    final cardWidth = (screenWidth * 0.56).clamp(
      205.0,
      220.0,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            onSeeAll: onSeeAll,
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,

              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),

              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              // Chuẩn bị trước khoảng 2 card khi vuốt.
              cacheExtent: cardWidth * 2,

              itemCount: rooms.length,

              separatorBuilder: (_, _) =>
                  const SizedBox(width: 12),

              itemBuilder: (context, index) {
                final room = rooms[index];

                return RepaintBoundary(
                  child: SizedBox(
                    width: cardWidth,
                    child: HomeRoomCard(
                      room: room,
                      isFavorite:
                          favoriteIds.contains(room.id),

                      onTap: () {
                        onRoomTap(room);
                      },

                      onFavoriteTap: () {
                        onFavoriteTap(room);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  final String title;
  final VoidCallback onSeeAll;

  static const _greenDark = Color(0xFF008C72);
  static const _text = Color(0xFF17211F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                height: 1.15,
                letterSpacing: -0.2,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(18),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}