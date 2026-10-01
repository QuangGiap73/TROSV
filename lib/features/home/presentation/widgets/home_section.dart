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

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      letterSpacing: -.15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF17201E),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF008E79),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 278,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rooms.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final room = rooms[index];

                return HomeRoomCard(
                  room: room,
                  isFavorite: favoriteIds.contains(room.id),
                  onTap: () => onRoomTap(room),
                  onFavoriteTap: () => onFavoriteTap(room),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
